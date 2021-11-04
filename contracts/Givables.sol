// SPDX-License-Identifier: GPL-3.0
/*
          ________.__             ___.   .__                 
         /  _____/|__|__  _______ \_ |__ |  |   ____   ______
        /   \  ___|  \  \/ /\__  \ | __ \|  | _/ __ \ /  ___/
        \    \_\  \  |\   /  / __ \| \_\ \  |_\  ___/ \___ \ 
         \______  /__| \_/  (____  /___  /____/\___  >____  >
                \/               \/    \/          \/     \/ 

Authored by: axantillon.eth
Credits:
Structure for URI handling based from (DEVS) 0x25ed58c027921E14D86380eA2646E3a1B5C55A8b
Structure for Admin Mgmt and token issuing (Buildspace) 0x322A88a26C23D45c7887711caDF055275701738E
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Givables is Ownable, ERC721Enumerable {
    mapping(address => bool) public claimed;
    mapping(address => bool) private admins;

    string baseURI;
    string description;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    bool allowsTransfers = false;

    event Claim(
        address indexed _receiver,
        uint256 _contractIndex,
        bool _isAdmin
    );

    constructor(string memory _baseURI, string memory _desc) ERC721("Givables", "GVB") {
        admins[msg.sender] = true;
        baseURI = _baseURI;
        description = _desc;
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
        _tokenIdTracker.increment();

        return newTokenId;
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

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Givables #',
                        toString(_tokenId),
                        '","description": "',
                        description,
                        '","image": "',
                        baseURI,
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function updateTokenURI(string memory _uri) external onlyAdmin {
        baseURI = _uri;
    }

    function updateDescription(string memory _desc) external onlyAdmin {
        description = _desc;
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
