// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IdentityManager} from "../../../src/IdentityManager.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";

contract IdentityManagerTest is Test {
    HelperConfig public helperConfig;
    IdentityManager public identityManager;
    address public testUser = address(1);

    function setUp() public {
        // Deploying identity manager locally to check dumb verify proof for local testing
        identityManager = new IdentityManager(address(0), "", "");
    }

    function testDumbVerify() public {
        identityManager.dumbVerify(testUser);
        bool tf = identityManager.getIsVerified(testUser);
        assertEq(tf, true);
    }
}
