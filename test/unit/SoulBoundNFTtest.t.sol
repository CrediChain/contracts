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
}
