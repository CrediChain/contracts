// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SoulBoundNFT} from "../../../src/SoulBoundNFT.sol";
import {CrediChainCore} from "../../../src/CrediChainCore.sol";
import {IdentityManager} from "../../../src/IdentityManager.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";

contract SoulBoundNFTTest is Test {
    HelperConfig public config;
    SoulBoundNFT public soulBoundNFT;
    CrediChainCore public credCore;
    IdentityManager public identitymanager;
    address owner = address(80085);
    address verifiedInstitution = address(2);
    address unverifiedInstitution = address(2);
    address student = address(1);

    function setUp() public {
        // Initialise config for constructor params
        config = new HelperConfig();
        // Deploy all contracts as the owner
        vm.startPrank(owner);
        soulBoundNFT = new SoulBoundNFT(owner);
        identitymanager = new IdentityManager(address(0), "", "");
        credCore = new CrediChainCore(address(soulBoundNFT), address(identitymanager));
        // Call setCrediChainCore to set the CrediChainCore address as owner
        soulBoundNFT.setCrediChainCore(address(credCore));
        // Call setIdentityManager to set the IdentityManager address as owner
        soulBoundNFT.setIdentityManager(address(identitymanager));
        // Verify an institution as an owner
        credCore.verifyInstitution(verifiedInstitution);
        // Verify with world id(mock) for owner, student and verified institution
        identitymanager.dumbVerify(owner);
        identitymanager.dumbVerify(verifiedInstitution);
        identitymanager.dumbVerify(student);

        vm.stopPrank();
    }

    function testMintModifiers() public {
        // Verify a institution as an owner
        vm.prank(owner);
        credCore.verifyInstitution(unverifiedInstitution);
        // Mint a soul-bound NFT to a student as a verified institution
        vm.prank(unverifiedInstitution);
        uint256 tokenId = soulBoundNFT.safeMint(unverifiedInstitution, student, "https://example.com");
        // Assertions
        assertEq(soulBoundNFT.ownerOf(tokenId), student);
        assertEq(soulBoundNFT.tokenURI(tokenId), "https://example.com");
        vm.expectRevert();
        vm.prank(address(0));
        soulBoundNFT.safeMint(msg.sender, student, "https://example.com");
    }

    function testGetTokenFromAddress() public {
        // Mint three NFTs as a verified institution to the same student
        vm.startPrank(verifiedInstitution);
        soulBoundNFT.safeMint(verifiedInstitution, student, "first");
        soulBoundNFT.safeMint(verifiedInstitution, student, "second");
        soulBoundNFT.safeMint(verifiedInstitution, student, "third");
        vm.stopPrank();
        // Call the getter to test
        SoulBoundNFT.NFTData[] memory nft = soulBoundNFT.getTokensByAddress(student);
        // Assertions
        for (uint256 i = 0; i < nft.length; i++) {
            console.log(nft[i].tokenURI);
            console.log(nft[i].ownerAddress);
            assertEq(nft[i].ownerAddress, student);
        }
    }
}
