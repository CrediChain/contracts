// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SoulBoundNFT} from "../../src/SoulBoundNFT.sol";

contract SoulBoundNFTTest is Test {
    SoulBoundNFT public soulBoundNFT;
    address owner = address(80085);
    address user = address(1);

    function setUp() public {
        vm.prank(owner);
        soulBoundNFT = new SoulBoundNFT(owner);
    }

    function testSafeMint() public {
        vm.prank(owner);
        uint256 tokenId = soulBoundNFT.safeMint(user, "https://example.com");
        assertEq(soulBoundNFT.ownerOf(tokenId), user);
        assertEq(soulBoundNFT.tokenURI(tokenId), "https://example.com");
        vm.expectRevert();
        vm.prank(address(0));
        soulBoundNFT.safeMint(user, "https://example.com");
    }

    function testGetTokenFromAddress() public {
        vm.startPrank(owner);
        soulBoundNFT.safeMint(user, "first");
        soulBoundNFT.safeMint(user, "second");
        soulBoundNFT.safeMint(user, "third");
        vm.stopPrank();
        SoulBoundNFT.NFTData[] memory nft = soulBoundNFT.getTokensByAddress(
            user
        );
        for (uint256 i = 0; i < nft.length; i++) {
            console.log(nft[i].tokenURI);
            console.log(nft[i].ownerAddress);
            assertEq(nft[i].ownerAddress, user);
        }
    }
}
