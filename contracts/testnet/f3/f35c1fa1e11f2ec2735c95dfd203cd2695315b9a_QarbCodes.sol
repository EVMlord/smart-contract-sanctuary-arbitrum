// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import {
    ERC721URIStorage,
    ERC721
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {
    ReentrancyGuard
} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { DynamicBuffer } from "ethier/utils/DynamicBuffer.sol";
import { QarbCodesInterface } from "./interfaces/QarbCodesInterface.sol";
import { QrCode } from "./QrCode.sol";

struct QrCodeStruct {
    string text;
    string color;
}

contract QarbCodes is
    QarbCodesInterface,
    QrCode,
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;

    struct Person {
        string name;
        uint age;
    }

    Counters.Counter private _tokenIds;

    uint256 public constant MAX_COUNT_PER_TX = 5;
    uint256 public constant FREE_SUPPLY = 200;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant PHASE_2_LIMIT = 1900;
    uint256 public constant PHASE_3_LIMIT = 2000;
    uint256 public constant PHASE_4_LIMIT = 2000;
    uint256 public constant PHASE_5_LIMIT = 2000;
    // PHASE_6_LIMIT is the remainder to get to max supply 8888

    uint256 public constant PHASE_1_WHITELIST_MINT_PRICE = 0 ether;
    uint256 public constant PHASE_2_MINT_PRICE = 0.00075 ether;
    uint256 public constant PHASE_3_MINT_PRICE = 0.00125 ether;
    uint256 public constant PHASE_4_MINT_PRICE = 0.00175 ether;
    uint256 public constant PHASE_5_MINT_PRICE = 0.00225 ether;
    uint256 public constant PHASE_6_MINT_PRICE = 0.00275 ether;

    uint256 private _numAvailableTokens = MAX_SUPPLY;
    uint256 private _mintedAtStartOfPublicSale;
    mapping(uint256 => QrCodeStruct) public qrCodes;
    mapping(address => uint8) private _whiteList;
    mapping(address => bool) public freeMintAddresses;

    // Minting
    // The global gate whether any of the phases has started
    bool public hasLaunched = false;
    bool public isPublicSaleActive = false;
    bool public isPhase2Active = false;
    bool public isPhase3Active = false;
    bool public isPhase4Active = false;
    bool public isPhase5Active = false;
    bool public isPhase6Active = false;
    uint public freeMintedCount = 0;

    bytes private constant _TOKEN_DESCRIPTION =
        "QaRb Codes on Arbitrum - Stored entirely on the Arbitrum Blockchain";

    event QRCodeURIGenerated(string str);

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    function setWhiteList(
        address[] calldata addresses,
        uint8 numAllowedToMint
    ) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whiteList[addresses[i]] = numAllowedToMint;
        }
    }

    /**
     * @notice The White List Mints is active until everything is sold out, so
     *         even when the Public Sale is activated users can still claim
     *         their whitelist spot as long as the collection is not Sold Out
     *         yet.
     *
     * @param qrCodeText The text the user wants in their QaRb Code, limited
     *                   to a maximum of 42 characters.
     */
    function mintWhiteList(string memory qrCodeText) external override {
        uint8 count = 1;
        uint256 qrCodeTextLength = bytes(qrCodeText).length;

        require(
            qrCodeTextLength > 0 && qrCodeTextLength <= 42,
            "INPUT_TEXT_INVALID"
        );
        require(hasLaunched, "PUBLIC_MINT_INACTIVE");
        require(count <= _whiteList[msg.sender], "ALLOW_LIST_MAX_EXCEEDED");
        require(totalSupply() + count <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
        require(count > 0, "MINT_COUNT_REQUIRED");

        _whiteList[msg.sender] -= count;

        _mint(qrCodeText, count);
    }

    /**
     * @notice The Free Mint is active once the Public Sale is activated.
     *         Every user gets 1x free mint, until 200 free mints have been
     *         minted.
     *
     * @param qrCodeText The text the user wants in their QaRb Code, limited
     *                   to a maximum of 42 characters.
     */
    function mintFree(string memory qrCodeText) external override {
        uint256 count = 1;
        uint256 qrCodeTextLength = bytes(qrCodeText).length;

        require(
            qrCodeTextLength > 0 && qrCodeTextLength <= 42,
            "INPUT_TEXT_INVALID"
        );
        require(hasLaunched && isPublicSaleActive, "PUBLIC_MINT_INACTIVE");
        require(
            freeMintAddresses[msg.sender] == false,
            "FREE_MINT_ALREADY_CLAIMED"
        );
        require(freeMintedCount < FREE_SUPPLY, "FREE_SOLD_OUT");
        require(totalSupply() + count <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
        require(count > 0, "MINT_COUNT_REQUIRED");

        freeMintedCount = freeMintedCount + 1;
        freeMintAddresses[msg.sender] = true;

        _mint(qrCodeText, count);
    }

    /**
     * @notice The Paid Mint is active once the Public Sale is activated.
     *
     * @param qrCodeText The text the user wants in their QaRb Code, limited
     *                   to a maximum of 42 characters.
     * @param count      The number of QaRb Codes to mint. Limited to a certain
     *                   maximum per transaction.
     */
    function mint(
        string memory qrCodeText,
        uint256 count
    ) external payable override {
        uint256 cost = currentMintPrice();
        uint256 qrCodeTextLength = bytes(qrCodeText).length;

        require(
            qrCodeTextLength > 0 && qrCodeTextLength <= 42,
            "INPUT_TEXT_INVALID"
        );
        require(hasLaunched && isPublicSaleActive, "PUBLIC_MINT_INACTIVE");
        require(totalSupply() + count <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
        require(msg.value >= count * cost, "INCORRECT_ETH_AMOUNT");
        require(count > 0 && count <= MAX_COUNT_PER_TX, "MINT_COUNT_INCORRECT");
        require(count > 0, "MINT_COUNT_REQUIRED");

        _mint(qrCodeText, count);
    }

    /**
     * @notice The Team Mint is active at all time, but obviously limited to
     *         the Max Supply.
     *
     * @param qrCodeText The text the user wants in their QaRb Code, limited
     *                   to a maximum of 42 characters.
     * @param count      The number of QaRb Codes to mint. Limited to a certain
     *                   maximum per transaction.
     */
    function mintTeam(
        string memory qrCodeText,
        uint256 count
    ) external override onlyOwner {
        require(totalSupply() + count <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
        require(count > 0, "MINT_COUNT_REQUIRED");
        uint256 qrCodeTextLength = bytes(qrCodeText).length;

        require(
            qrCodeTextLength > 0 && qrCodeTextLength <= 42,
            "INPUT_TEXT_INVALID"
        );
        _mint(qrCodeText, count);
    }

    function toggleLaunch() external override onlyOwner {
        hasLaunched = !hasLaunched;
    }

    /**
     * @notice Toggles the state of the Public Sale.
     *
     * @dev The public sale can be de-activated but the
     *      _mintedAtStartOfPublicSale can never be reset if the public sale is
     *      enabled for a 2nd (or more) times due to the Phases logic depending
     *      on the first toggle.
     */
    function togglePublicSaleActive() external override onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
        if (isPublicSaleActive) {
            isPhase2Active = true;
            if (!(_mintedAtStartOfPublicSale > 0))
                _mintedAtStartOfPublicSale = _tokenIds.current();
        }
    }

    function withdrawBalance(
        address payable to
    ) external override onlyOwner nonReentrant {
        require(address(this).balance > 0, "Contract has no balance");
        uint256 balance = address(this).balance;
        (bool success, ) = to.call{ value: balance }("");
        require(success, "Transfer failed");
    }

    function maxSupply() external view virtual override returns (uint256) {
        return MAX_SUPPLY;
    }

    function tokenQrCodeText(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        require(_exists(tokenId), "TOKEN_DOES_NOT_EXIST");
        return qrCodes[tokenId].text;
    }

    function whiteListSpots(
        address addr
    ) external view virtual override returns (uint256) {
        return _whiteList[addr];
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TOKEN_DOES_NOT_EXIST");

        QrCodeStruct memory qrCode = qrCodes[tokenId];
        bytes memory svg = bytes(_generateQRCode(qrCode.text, qrCode.color));
        bytes memory title = abi.encodePacked(
            "#",
            Strings.toString(tokenId),
            " - ",
            qrCode.text
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                title,
                                '","description":"',
                                _TOKEN_DESCRIPTION,
                                '","image_data":"data:image/svg+xml;base64,',
                                Base64.encode(svg),
                                '","attributes":',
                                _textAttributesAsJSON(tokenId),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function totalSupply() public view virtual override returns (uint256) {
        return MAX_SUPPLY - _numAvailableTokens;
    }

    function currentMintPrice() public view override returns (uint256) {
        // This line should never take effect as this function is only called
        // from mint() which can only be called when in Phase 2 and onwards.
        if (!isPublicSaleActive) return PHASE_1_WHITELIST_MINT_PRICE;

        if (isPhase2Active) return PHASE_2_MINT_PRICE;
        if (isPhase3Active) return PHASE_3_MINT_PRICE;
        if (isPhase4Active) return PHASE_4_MINT_PRICE;
        if (isPhase5Active) return PHASE_5_MINT_PRICE;

        // Phase 6 should be active
        require(isPhase6Active, "PHASE_6_SHOULD_BE_ACTIVE");
        return PHASE_6_MINT_PRICE;
    }

    /**
     * @notice Executes the actual minting.
     *
     * @dev No conditions are checked here so please make sure this function is
     *      called from other functions that do the necessary enforcement of
     *      requirements.
     *
     * @param qrCodeText The text the user wants in their QaRb Code, limited
     *                   to a maximum of 42 characters.
     * @param count      The number of QaRb Codes to mint. Limited to a certain
     *                   maximum per transaction.
     */
    function _mint(string memory qrCodeText, uint256 count) private {
        uint256 updatedNumAvailableTokens = _numAvailableTokens;

        for (uint256 i; i < count; ++i) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(msg.sender, newTokenId);
            string memory color = _randomColor(newTokenId);
            QrCodeStruct memory qrCode = QrCodeStruct(qrCodeText, color);
            qrCodes[newTokenId] = qrCode;

            _updatePhase(newTokenId);
            --updatedNumAvailableTokens;
        }

        _numAvailableTokens = updatedNumAvailableTokens;
    }

    function _updatePhase(uint256 newTokenId) private {
        if (
            isPhase2Active &&
            newTokenId == _mintedAtStartOfPublicSale + PHASE_2_LIMIT
        ) {
            isPhase2Active = false;
            isPhase3Active = true;
            return;
        }

        if (
            isPhase3Active &&
            newTokenId ==
            _mintedAtStartOfPublicSale + PHASE_2_LIMIT + PHASE_3_LIMIT
        ) {
            isPhase3Active = false;
            isPhase4Active = true;
            return;
        }

        if (
            isPhase4Active &&
            newTokenId ==
            _mintedAtStartOfPublicSale +
                PHASE_2_LIMIT +
                PHASE_3_LIMIT +
                PHASE_4_LIMIT
        ) {
            isPhase4Active = false;
            isPhase5Active = true;
            return;
        }

        if (
            isPhase5Active &&
            newTokenId ==
            _mintedAtStartOfPublicSale +
                PHASE_2_LIMIT +
                PHASE_3_LIMIT +
                PHASE_4_LIMIT +
                PHASE_5_LIMIT
        ) {
            isPhase5Active = false;
            isPhase6Active = true;
        }
    }

    function _textAttributesAsJSON(
        uint256 tokenId
    ) private view returns (string memory json) {
        QrCodeStruct memory qrCode = qrCodes[tokenId];
        string memory attributeAsString = qrCode.text;
        string memory bgColorValue = qrCode.color;

        return
            string(
                abi.encodePacked(
                    '[{"trait_type":"Value", "value":"',
                    attributeAsString,
                    '"}, {"trait_type":"Background", "value":"#',
                    bgColorValue,
                    '"}]'
                )
            );
    }

    function _randomColor(
        uint256 tokenId
    ) private view returns (string memory) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    block.number,
                    tokenId
                )
            )
        );

        uint8 count = 0;
        uint8 r = uint8(random >> (0 * 8));
        if (r < 128) {
            count++;
        }
        uint8 g = uint8(random >> (1 * 8));
        if (g < 128) {
            count++;
        }
        uint8 b = uint8(random >> (2 * 8));
        if (b < 128) {
            count++;
        }

        if (count >= 2) {
            uint8 max = _max(r, g, b);
            if (r == max) {
                r = 255;
            } else if (g == max) {
                g = 255;
            } else {
                b = 255;
            }
        }

        bytes memory color = new bytes(3);
        color[0] = r < 50 ? bytes1(uint8(50)) : bytes1(r);
        color[1] = g < 50 ? bytes1(uint8(50)) : bytes1(g);
        color[2] = b < 50 ? bytes1(uint8(50)) : bytes1(b);

        return _bytesToHexString(color);
    }

    function _max(uint8 a, uint8 b, uint8 c) private pure returns (uint8) {
        if (a >= b && a >= c) {
            return a;
        } else if (b >= a && b >= c) {
            return b;
        } else {
            return c;
        }
    }

    function _bytesToHexString(
        bytes memory data
    ) private pure returns (string memory) {
        bytes memory hexAlphabet = "0123456789abcdef";
        bytes memory result = new bytes(2 * data.length);
        for (uint256 i = 0; i < data.length; i++) {
            result[2 * i] = hexAlphabet[uint8(data[i] >> 4)];
            result[2 * i + 1] = hexAlphabet[uint8(data[i] & 0x0f)];
        }
        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity_ The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity_ + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity_)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity_, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity_, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        checkOverflow(buffer, data.length);
        appendUnchecked(buffer, data);
    }

    /// @notice Appends data encoded as Base64 to buffer.
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// Author: Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
    /// Author: Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
    /// Author: Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos.
    function appendSafeBase64(
        bytes memory buffer,
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure {
        uint256 dataLength = data.length;

        if (data.length == 0) {
            return;
        }

        uint256 encodedLength;
        uint256 r;
        assembly {
            // For each 3 bytes block, we will have 4 bytes in the base64
            // encoding: `encodedLength = 4 * divCeil(dataLength, 3)`.
            // The `shl(2, ...)` is equivalent to multiplying by 4.
            encodedLength := shl(2, div(add(dataLength, 2), 3))

            r := mod(dataLength, 3)
            if noPadding {
                // if r == 0 => no modification
                // if r == 1 => encodedLength -= 2
                // if r == 2 => encodedLength -= 1
                encodedLength := sub(
                    encodedLength,
                    add(iszero(iszero(r)), eq(r, 1))
                )
            }
        }

        checkOverflow(buffer, encodedLength);

        assembly {
            let nextFree := mload(0x40)

            // Store the table into the scratch space.
            // Offsetted by -1 byte so that the `mload` will load the character.
            // We will rewrite the free memory pointer at `0x40` later with
            // the allocated size.
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(
                0x3f,
                sub(
                    "ghijklmnopqrstuvwxyz0123456789-_",
                    // The magic constant 0x0230 will translate "-_" + "+/".
                    mul(iszero(fileSafe), 0x0230)
                )
            )

            // Skip the first slot, which stores the length.
            let ptr := add(add(buffer, 0x20), mload(buffer))
            let end := add(data, dataLength)

            // Run over the input, 3 bytes at a time.
            // prettier-ignore
            // solhint-disable-next-line no-empty-blocks
            for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

            if iszero(noPadding) {
                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
            }

            mstore(buffer, add(mload(buffer), encodedLength))
            mstore(0x40, nextFree)
        }
    }

    /// @notice Returns the capacity of a given buffer.
    function capacity(bytes memory buffer) internal pure returns (uint256) {
        uint256 cap;
        assembly {
            cap := sub(mload(sub(buffer, 0x20)), 0x40)
        }
        return cap;
    }

    /// @notice Reverts if the buffer will overflow after appending a given
    /// number of bytes.
    function checkOverflow(bytes memory buffer, uint256 addedLength)
        internal
        pure
    {
        uint256 cap = capacity(buffer);
        uint256 newLength = buffer.length + addedLength;
        if (cap < newLength) {
            revert("DynamicBuffer: Appending out of bounds.");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface QarbCodesInterface {
    function setWhiteList(
        address[] calldata addresses,
        uint8 numAllowedToMint
    ) external;

    function mintWhiteList(string memory qrCodeText) external;

    function mintFree(string memory qrCodeText) external;

    function mint(string memory qrCodeText, uint256 count) external payable;

    function mintTeam(string memory qrCodeText, uint256 count) external;

    function toggleLaunch() external;

    function togglePublicSaleActive() external;

    function withdrawBalance(address payable to) external;

    function maxSupply() external view returns (uint256);

    function tokenQrCodeText(
        uint256 tokenId
    ) external view returns (string memory);

    function whiteListSpots(address addr) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function currentMintPrice() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import {
    ERC721URIStorage,
    ERC721
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { DynamicBuffer } from "ethier/utils/DynamicBuffer.sol";
import { QarbCodesInterface } from "./interfaces/QarbCodesInterface.sol";

struct QRMatrix {
    uint256[29][29] matrix;
    uint256[29][29] reserved;
}

contract QrCode {
    function _generateQRCode(
        string memory handle,
        string memory color
    ) internal pure returns (string memory) {
        // 1. Create base matrix
        QRMatrix memory qrMatrix = _createBaseMatrix();
        // 2. Encode Data
        uint8[] memory encoded = _encode(string(abi.encodePacked(handle)));
        // 3. Generate buff
        uint256[44] memory buf = _generateBuf(encoded);

        // 4. Augument ECCs
        uint256[70] memory bufWithECCs = _augumentECCs(buf);

        // 5. put data into matrix
        _putData(qrMatrix, bufWithECCs);

        // 6. mask data
        _maskData(qrMatrix);

        // 7. Put format info
        _putFormatInfo(qrMatrix);
        // emit MatrixCreated(qrMatrix.matrix);

        // 8. Compose SVG and convert to base64
        return _generateQRURIByteVersion(qrMatrix, color);
    }

    function _createBaseMatrix() internal pure returns (QRMatrix memory) {
        QRMatrix memory _qrMatrix;
        uint256 size = 29;
        uint8[2] memory aligns = [4, 20];

        _qrMatrix = _blit(
            _qrMatrix,
            0,
            0,
            9,
            9,
            [0x7f, 0x41, 0x5d, 0x5d, 0x5d, 0x41, 0x17f, 0x00, 0x40]
        );

        _qrMatrix = _blit(
            _qrMatrix,
            size - 8,
            0,
            8,
            9,
            [0x100, 0x7f, 0x41, 0x5d, 0x5d, 0x5d, 0x41, 0x7f, 0x00]
        );

        _blit(
            _qrMatrix,
            0,
            size - 8,
            9,
            8,
            [
                uint16(0xfe),
                uint16(0x82),
                uint16(0xba),
                uint16(0xba),
                uint16(0xba),
                uint16(0x82),
                uint16(0xfe),
                uint16(0x00),
                uint16(0x00)
            ]
        );

        for (uint256 i = 9; i < size - 8; ++i) {
            _qrMatrix.matrix[6][i] = _qrMatrix.matrix[i][6] = ~i & 1;
            _qrMatrix.reserved[6][i] = _qrMatrix.reserved[i][6] = 1;
        }

        // alignment patterns
        for (uint8 i = 0; i < 2; ++i) {
            uint8 minj = i == 0 || i == 1 ? 1 : 0;
            uint8 maxj = i == 0 ? 1 : 2;
            for (uint8 j = minj; j < maxj; ++j) {
                _blit(
                    _qrMatrix,
                    aligns[i],
                    aligns[j],
                    5,
                    5,
                    [
                        uint16(0x1f),
                        uint16(0x11),
                        uint16(0x15),
                        uint16(0x11),
                        uint16(0x1f),
                        uint16(0x00),
                        uint16(0x00),
                        uint16(0x00),
                        uint16(0x00)
                    ]
                );
            }
        }

        return _qrMatrix;
    }

    function _encode(string memory str) internal pure returns (uint8[] memory) {
        bytes memory byteString = bytes(str);
        uint8[] memory encodedArr = new uint8[](byteString.length);

        for (uint8 i = 0; i < encodedArr.length; i++) {
            encodedArr[i] = uint8(byteString[i]);
        }

        return encodedArr;
    }

    function _generateBuf(
        uint8[] memory data
    ) internal pure returns (uint256[44] memory) {
        uint256[44] memory buf;
        uint256 dataLen = data.length;
        uint8 maxBufLen = 44;

        uint256 bits = 0;
        uint256 remaining = 8;

        (buf, bits, remaining) = _pack(buf, bits, remaining, 4, 4, 0);
        (buf, bits, remaining) = _pack(buf, bits, remaining, dataLen, 8, 0);

        for (uint8 i = 0; i < dataLen; ++i) {
            (buf, bits, remaining) = _pack(
                buf,
                bits,
                remaining,
                data[i],
                8,
                i + 1
            );
        }

        (buf, bits, remaining) = _pack(buf, bits, remaining, 0, 4, dataLen + 1);

        for (uint256 i = data.length + 2; i < maxBufLen - 1; i++) {
            buf[i] = 0xec;
            buf[i + 1] = 0x11;
        }

        return buf;
    }

    function _maskData(QRMatrix memory _qrMatrix) internal pure {
        for (uint256 i = 0; i < 29; ++i) {
            for (uint256 j = 0; j < 29; ++j) {
                if (_qrMatrix.reserved[i][j] == 0) {
                    if (j % 3 == 0) {
                        _qrMatrix.matrix[i][j] ^= 1;
                    } else {
                        _qrMatrix.matrix[i][j] ^= 0;
                    }
                }
            }
        }
    }

    function _augumentECCs(
        uint256[44] memory poly
    ) internal pure returns (uint256[70] memory) {
        uint8 nblocks = 1;
        uint8[26] memory genpoly = [
            173,
            125,
            158,
            2,
            103,
            182,
            118,
            17,
            145,
            201,
            111,
            28,
            165,
            53,
            161,
            21,
            245,
            142,
            13,
            102,
            48,
            227,
            153,
            145,
            218,
            70
        ];

        uint8[2] memory subsizes = [0, 44];
        uint256 nitemsperblock = 44;
        uint256[26][1] memory eccs;
        uint256[70] memory result;
        uint256[44] memory partPoly;

        for (uint256 i; i < 44; i++) {
            partPoly[i] = poly[i];
        }

        eccs[0] = _calculateECC(partPoly, genpoly);

        for (uint8 i = 0; i < nitemsperblock; ++i) {
            for (uint8 j = 0; j < nblocks; ++j) {
                result[i] = poly[subsizes[j] + i];
            }
        }
        for (uint8 i = 0; i < genpoly.length; ++i) {
            for (uint8 j = 0; j < nblocks; ++j) {
                result[i + 44] = eccs[j][i];
            }
        }

        return result;
    }

    function _calculateECC(
        uint256[44] memory poly,
        uint8[26] memory genpoly
    ) internal pure returns (uint256[26] memory) {
        uint256[256] memory GF256_MAP;
        uint256[256] memory GF256_INVMAP;
        uint256[70] memory modulus;
        uint8 polylen = uint8(poly.length);
        uint8 genpolylen = uint8(genpoly.length);
        uint256[26] memory result;
        uint256 gf256_value = 1;

        GF256_INVMAP[0] = 0;

        for (uint256 i = 0; i < 255; ++i) {
            GF256_MAP[i] = gf256_value;
            GF256_INVMAP[gf256_value] = i;
            gf256_value = (gf256_value * 2) ^ (gf256_value >= 128 ? 0x11d : 0);
        }

        for (uint8 i = 0; i < 44; i++) {
            modulus[i] = poly[i];
        }

        for (uint8 i = 44; i < 70; ++i) {
            modulus[i] = 0;
        }

        for (uint8 i = 0; i < polylen; ) {
            uint256 idx = modulus[i++];
            if (idx > 0) {
                uint256 quotient = GF256_INVMAP[idx];
                for (uint8 j = 0; j < genpolylen; ++j) {
                    modulus[i + j] ^= GF256_MAP[(quotient + genpoly[j]) % 255];
                }
            }
        }

        for (uint8 i = 0; i < modulus.length - polylen; i++) {
            result[i] = modulus[polylen + i];
        }

        return result;
    }

    function _pack(
        uint256[44] memory buf,
        uint256 bits,
        uint256 remaining,
        uint256 x,
        uint256 n,
        uint256 index
    ) internal pure returns (uint256[44] memory, uint256, uint256) {
        uint256[44] memory newBuf = buf;
        uint256 newBits = bits;
        uint256 newRemaining = remaining;

        if (n >= remaining) {
            newBuf[index] = bits | (x >> (n -= remaining));
            newBits = 0;
            newRemaining = 8;
        }
        if (n > 0) {
            newBits |= (x & ((1 << n) - 1)) << (newRemaining -= n);
        }

        return (newBuf, newBits, newRemaining);
    }

    function _blit(
        QRMatrix memory qrMatrix,
        uint256 y,
        uint256 x,
        uint256 h,
        uint256 w,
        uint16[9] memory data
    ) internal pure returns (QRMatrix memory) {
        for (uint256 i = 0; i < h; ++i) {
            for (uint256 j = 0; j < w; ++j) {
                qrMatrix.matrix[y + i][x + j] = (data[i] >> j) & 1;
                qrMatrix.reserved[y + i][x + j] = 1;
            }
        }

        return qrMatrix;
    }

    function _putFormatInfo(QRMatrix memory _qrMatrix) internal pure {
        uint8[15] memory infoA = [
            0,
            1,
            2,
            3,
            4,
            5,
            7,
            8,
            22,
            23,
            24,
            25,
            26,
            27,
            28
        ];

        uint8[15] memory infoB = [
            28,
            27,
            26,
            25,
            24,
            23,
            22,
            21,
            7,
            5,
            4,
            3,
            2,
            1,
            0
        ];

        for (uint8 i = 0; i < 15; ++i) {
            uint8 r = infoA[i];
            uint8 c = infoB[i];
            _qrMatrix.matrix[r][8] = _qrMatrix.matrix[8][c] = (24144 >> i) & 1;
        }
    }

    function _putData(
        QRMatrix memory _qrMatrix,
        uint256[70] memory data
    ) internal pure returns (QRMatrix memory) {
        int256 n = 29;
        uint256 k = 0;
        int8 dir = -1;

        for (int256 i = n - 1; i >= 0; i = i - 2) {
            if (i == 6) {
                --i;
            } // skip the entire timing pattern column
            int256 jj = dir < 0 ? n - 1 : int256(0);
            for (int256 j = 0; j < n; j++) {
                for (int256 ii = int256(i); ii > int256(i) - 2; ii--) {
                    if (
                        _qrMatrix.reserved[uint256(jj)][uint256(ii)] == 0 &&
                        k >> 3 < 70
                    ) {
                        _qrMatrix.matrix[uint256(jj)][uint256(ii)] =
                            (data[k >> 3] >> (~k & 7)) &
                            1;
                        ++k;
                    }
                }

                if (dir == -1) {
                    jj = jj - 1;
                } else {
                    jj = jj + 1;
                }
            }

            dir = -dir;
        }

        return _qrMatrix;
    }

    function _generateQRURIByteVersion(
        QRMatrix memory _qrMatrix,
        string memory color
    ) internal pure returns (string memory) {
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        DynamicBuffer.appendSafe(
            svgBytes,
            abi.encodePacked(
                '<svg viewBox="0 0 300 300" width="500" height="500" xmlns="http://www.w3.org/2000/svg"><style>.bg{fill:#', // solhint-disable-line
                color,
                '}.fg{fill:#000}</style><rect class="bg" x="0" y="0" width="500" height="500"></rect>' // solhint-disable-line
            )
        );

        uint256 yo = 32;
        for (uint256 y = 0; y < 29; ++y) {
            uint256 xo = 32;
            for (uint256 x = 0; x < 29; ++x) {
                if (_qrMatrix.matrix[y][x] == 1) {
                    DynamicBuffer.appendSafe(
                        svgBytes,
                        abi.encodePacked(
                            '<rect x="', // solhint-disable-line
                            Strings.toString(xo),
                            '" y="', // solhint-disable-line
                            Strings.toString(yo),
                            '" class="fg" width="8" height="8"/>' // solhint-disable-line
                        )
                    );
                }
                xo += 8;
            }
            yo += 8;
        }

        DynamicBuffer.appendSafe(svgBytes, "</svg>");
        return string(svgBytes);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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