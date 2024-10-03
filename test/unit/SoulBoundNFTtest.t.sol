// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SoulBoundNFT} from "../../src/SoulBoundNFT.sol";

contract NFTTest is Test {
    SoulBoundNFT public soulBoundNFT;
    address user = address(1);

    function setUp() public {
        soulBoundNFT = new SoulBoundNFT(address(this));
    }

    function testMint() public {
        uint256 tokenId = soulBoundNFT.safeMint(user, "https://example.com");
        console.log(soulBoundNFT.tokenURI(tokenId));
        console.log(soulBoundNFT.tokenURI(tokenId));
    }

    function testGetTokenFromAddress() public {
        soulBoundNFT.safeMint(user, "univ_cred");
        soulBoundNFT.safeMint(user, "sexyone");
        SoulBoundNFT.NFTData[] memory nft = soulBoundNFT.getTokensByAddress(
            user
        );
        for (uint256 i = 0; i < nft.length; i++) {
            console.log(nft[i].tokenURI);
            console.log(nft[i].ownerAddress);
        }
    }
}
