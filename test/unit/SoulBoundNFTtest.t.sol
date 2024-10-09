// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SoulBoundNFT} from "../../src/SoulBoundNFT.sol";
import {CrediChainCore} from "../../src/CrediChainCore.sol";
import {IdentityManager} from "../../src/IdentityManager.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract SoulBoundNFTTest is Test {
    HelperConfig public config;
    SoulBoundNFT public soulBoundNFT;
    CrediChainCore public credCore;
    IdentityManager public identitymanager;
    address owner = address(80085);
    address verifiedInstitution = address(2);
    address student = address(1);

    function setUp() public {
        config = new HelperConfig();
        vm.startPrank(owner);
        soulBoundNFT = new SoulBoundNFT(owner);
        identitymanager = new IdentityManager(address(0), "", "");
        credCore = new CrediChainCore(
            address(soulBoundNFT),
            address(identitymanager)
        );
        soulBoundNFT.setCrediChainCore(address(credCore));
        credCore.verifyInstitution(verifiedInstitution);
        identitymanager.dumbVerify(owner);
        vm.stopPrank();
        vm.prank(verifiedInstitution);
        identitymanager.dumbVerify(verifiedInstitution);
    }

    function testMintModifiers() public {
        vm.startPrank(owner);
        credCore.verifyInstitution(owner);
        uint256 tokenId = soulBoundNFT.safeMint(student, "https://example.com");
        vm.stopPrank();
        assertEq(soulBoundNFT.ownerOf(tokenId), student);
        assertEq(soulBoundNFT.tokenURI(tokenId), "https://example.com");
        vm.expectRevert();
        vm.prank(address(0));
        soulBoundNFT.safeMint(student, "https://example.com");
    }

    function testGetTokenFromAddress() public {
        vm.startPrank(owner);
        credCore.verifyInstitution(owner);
        soulBoundNFT.safeMint(student, "first");
        soulBoundNFT.safeMint(student, "second");
        soulBoundNFT.safeMint(student, "third");
        vm.stopPrank();
        SoulBoundNFT.NFTData[] memory nft = soulBoundNFT.getTokensByAddress(
            student
        );
        for (uint256 i = 0; i < nft.length; i++) {
            console.log(nft[i].tokenURI);
            console.log(nft[i].ownerAddress);
            assertEq(nft[i].ownerAddress, student);
        }
    }

    function testIssueCredential() public {
        vm.startPrank(verifiedInstitution);
        credCore.issueCredential(student, "BTECHVSEM");
        SoulBoundNFT.NFTData[] memory nft = soulBoundNFT.getTokensByAddress(
            student
        );
        for (uint256 i = 0; i < nft.length; i++) {
            console.log(nft[i].tokenURI);
            console.log(nft[i].ownerAddress);
            assertEq(nft[i].ownerAddress, student);
        }
        vm.stopPrank();
    }
}
