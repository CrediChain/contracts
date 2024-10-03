// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SoulBoundNFT
 * @author CrediChain
 * @notice ERC721 that is not transferable, representing educational credentials
 */
contract SoulBoundNFT is ERC721, ERC721URIStorage, Ownable {
    struct NFTData {
        uint256 tokenId;
        address ownerAddress;
        string tokenURI;
    }
    uint256 private _nextTokenId;

    NFTData[] public nftArray;

    mapping(address => uint256) private nftData;

    error SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    error SoulBoundNFT__TokenDoesNotExist();

    event CredentialMinted(
        address indexed to,
        uint256 indexed tokenId,
        string uri
    );
    event CredentialRevoked(uint256 indexed tokenId);

    constructor(
        address initialOwner
    ) ERC721("EducationalCredential", "EDU") Ownable(initialOwner) {}

    function safeMint(
        address to,
        string memory uri
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        nftArray.push(
            NFTData({tokenId: tokenId, ownerAddress: to, tokenURI: uri})
        );
        nftData[to] = tokenId;
        emit CredentialMinted(to, tokenId, uri);
        return tokenId;
    }

    function revoke(uint256 tokenId) public onlyOwner {
        // Check if the token's owner is not the zero address instead of using _exists
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner == address(0)) revert SoulBoundNFT__TokenDoesNotExist();
        _burn(tokenId);
        emit CredentialRevoked(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721) returns (address) {
        address from = _ownerOf(tokenId);
        require(
            from == address(0) || to == address(0),
            "SoulBoundNFT: token transfer is not allowed"
        );
        return super._update(to, tokenId, auth);
    }

    // Disable transfer functions
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override(ERC721, IERC721) {
        revert SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure override(ERC721, IERC721) {
        revert SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override(ERC721, IERC721) {
        revert SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    }

    // Disable approval functions
    function approve(address, uint256) public pure override(ERC721, IERC721) {
        revert SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    }

    function setApprovalForAll(
        address,
        bool
    ) public pure override(ERC721, IERC721) {
        revert SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    }

    function getTokensByAddress(
        address _address
    ) public view returns (NFTData[] memory) {
        uint256 counter = 0;
        NFTData[] memory vault;
        for (uint256 i = 0; i < nftArray.length; i++) {
            if (nftArray[i].ownerAddress == _address) {
                vault[counter] = (nftArray[i]);
            }
            counter++;
        }
        return vault;
    }
}
