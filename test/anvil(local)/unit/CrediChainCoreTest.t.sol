// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SoulBoundNFT} from "../../../src/SoulBoundNFT.sol";
import {CrediChainCore} from "../../../src/CrediChainCore.sol";
import {IdentityManager} from "../../../src/IdentityManager.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";

contract CrediChainCoreTest is Test {
    HelperConfig public config;
    SoulBoundNFT public soulBoundNFT;
    CrediChainCore public credCore;
    IdentityManager public identitymanager;
    address owner = address(80085);
    address verifiedInstitution = address(2);
    address student = address(1);

    function setUp() public {
        // Initialise config for constructor params
        config = new HelperConfig();
        // Deploy all contracts as the owner
        vm.startPrank(owner);
        soulBoundNFT = new SoulBoundNFT(owner);
        identitymanager = new IdentityManager(address(0), "", "");
        credCore = new CrediChainCore(
            address(soulBoundNFT),
            address(identitymanager)
        );
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

    function testIssueCredential() public {
        // Issue credential to a student as a fully verified institution
        vm.prank(verifiedInstitution);
        uint256 tokenId = credCore.issueCredential(
            student,
            "https://example.com"
        );
        // Assertions
        assertEq(credCore.getCredentialIssuer(tokenId), verifiedInstitution);
        SoulBoundNFT.NFTData[] memory nft = credCore.getStudentCredentials(
            student
        );
        for (uint256 i = 0; i < nft.length; i++) {
            assertEq(nft[i].tokenId, tokenId);
        }
    }

    function testRevokeCredential() public {
        // Issue credential to a student as a fully verified institution
        vm.startPrank(verifiedInstitution);
        uint256 tokenId = credCore.issueCredential(
            student,
            "https://example.com"
        );
        // Revoke the credential
        credCore.revokeCredential(tokenId);
        vm.stopPrank();
        // Assertions
        vm.expectRevert();
        soulBoundNFT.ownerOf(tokenId);
    }
}
