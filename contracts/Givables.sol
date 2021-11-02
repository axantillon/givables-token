// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Givables is ERC721URIStorage, Ownable {
    mapping(address => bool) public claimed;
    mapping(address => bool) private admins;

    string baseSvg =
        "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    bool allowsTransfers = false;

    struct Cohort {
        uint128 limit;
        uint128 tokenMinted;
        bytes32 merkleRoot;
    }

    event Claim(
        address indexed _receiver,
        uint256 _contractIndex,
        bool _isAdmin
    );

    constructor() ERC721("Givables", "GVB") {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true);
        _;
    }

    modifier limitCheck(address to) {
        require(!claimed[to], "Givables: address has already claimed token.");
        _;
    }

    function issueToken(address to, bool _isAdmin)
        internal
        limitCheck(to)
        returns (uint256)
    {
        claimed[to] = true;
        uint256 newTokenId = _tokenIdTracker.current();
        _safeMint(to, newTokenId);
        emit Claim(to, newTokenId, _isAdmin);

        setTokenURI(newTokenId);
        _tokenIdTracker.increment();

        return newTokenId;
    }

    function setTokenURI(uint256 _tokenId) internal onlyAdmin {
        string memory svg = string(
            abi.encodePacked(baseSvg, "Givables #", toString(_tokenId), "</text></svg>")
        );

        console.log("\n-------SVG----------");
        console.log(svg);
        console.log("--------------------\n");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Givables #',
                        toString(_tokenId),
                        '", "description": "Access to the Givables community of Undergraduate Artists", "image": "data:image/svg+xml;base64,',
                        // We add data:image/svg+xml;base64 and then append our base64 encode our svg.
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );

        console.log("\n------JSON----------");
        console.log(json);
        console.log("--------------------\n");

        _setTokenURI(
            _tokenId,
            string(abi.encodePacked("data:application/json;base64,", json))
        );
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    function adminIssueToken(address to) external onlyAdmin returns (uint256) {
        return issueToken(to, true);
    }

    function setAllowsTransfers(bool _allowsTransfers) external onlyAdmin {
        allowsTransfers = _allowsTransfers;
    }

    function updateAdmin(address _admin, bool isAdmin) external onlyOwner {
        admins[_admin] = isAdmin;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            from == address(0) || to == address(0) || allowsTransfers,
            "Not allowed to transfer"
        );
        return super._beforeTokenTransfer(from, to, tokenId);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
