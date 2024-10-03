// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {SoulBoundNFT} from "../src/SoulBoundNFT.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeploySoulBoundNFT is Script {
    function run() external returns (DeploySoulBoundNFT) {
        HelperConfig herlpConfig = new HelperConfig();
    }
}
