// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CrediChainCore.sol";

/**
 * @title SoulBoundNFT
 * @notice ERC721 that is not transferable, representing educational credentials
 */
contract SoulBoundNFT is ERC721, ERC721URIStorage, Ownable {
    struct NFTData {
        uint256 tokenId;
        address ownerAddress;
        string tokenURI;
    }
    uint256 private _nextTokenId;

    CrediChainCore public credCore;

    // Removed NFTData[] public nftArray;

    mapping(address => uint256[]) private nftData;

    error SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    error SoulBoundNFT__TokenDoesNotExist();
    error SoulBoundNFT__OnlyVerifiedInstitutions();

    event CredentialMinted(
        address indexed to,
        uint256 indexed tokenId,
        string uri
    );
    event CredentialRevoked(uint256 indexed tokenId);

    constructor(
        address initialOwner
    ) ERC721("EducationalCredential", "EDU") Ownable(initialOwner) {
        transferOwnership(initialOwner);
    }

    modifier onlyVerifiedInstitutions() {
        if (!credCore.verifiedInstitutions(msg.sender))
            revert SoulBoundNFT__OnlyVerifiedInstitutions();

        _;
    }

    function setCrediChainCore(address _address) public onlyOwner {
        credCore = CrediChainCore(_address);
    }

    function safeMint(
        address to,
        string memory uri
    ) public onlyVerifiedInstitutions returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        nftData[to].push(tokenId); // Add tokenId to the address's array
        emit CredentialMinted(to, tokenId, uri);
        return tokenId;
    }

    function revoke(uint256 tokenId) public onlyOwner {
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner == address(0)) revert SoulBoundNFT__TokenDoesNotExist();
        _burn(tokenId);
        // Remove the tokenId from nftData mapping
        uint256[] storage userTokens = nftData[tokenOwner];
        for (uint256 i = 0; i < userTokens.length; i++) {
            if (userTokens[i] == tokenId) {
                userTokens[i] = userTokens[userTokens.length - 1];
                userTokens.pop();
                break;
            }
        }
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

    // Disable transfer functions
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override(ERC721, IERC721) {
        revert SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    }

    function approve(address, uint256) public pure override(ERC721, IERC721) {
        revert SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    }

    function setApprovalForAll(
        address,
        bool
    ) public pure override(ERC721, IERC721) {
        revert SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal override {
        revert SoulBoundNFT__SoulBoundTokensCannotBeTransferred();
    }

    // Updated getTokensByAddress using the mapping
    function getTokensByAddress(
        address _address
    ) public view returns (NFTData[] memory) {
        uint256[] memory tokenIds = nftData[_address];
        NFTData[] memory vault = new NFTData[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            vault[i] = NFTData({
                tokenId: tokenId,
                ownerAddress: _address,
                tokenURI: tokenURI(tokenId)
            });
        }
        return vault;
    }
}
