// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {CrediChainCore} from "../src/CrediChainCore.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployCrediChainCore is Script {
    function run() external returns (CrediChainCore) {
        HelperConfig herlpConfig = new HelperConfig();
    }
}
