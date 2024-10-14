// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IdentityManager} from "../src/IdentityManager.sol";

contract DeployIdentityManager is Script {
    function run() external returns (IdentityManager) {
        vm.startBroadcast();

        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.Config memory config = helperConfig.getBaseSepoliaConfig();

        IdentityManager identityManager =
            new IdentityManager(config._WorldcoinRouterAddress, config._appid, config._actionId);

        vm.stopBroadcast();

        console2.log("App ID: ", config._appid);
        console2.log("Action ID: ", config._actionId);
        console2.log("Worldcoin Router Address: ", config._WorldcoinRouterAddress);
        console2.log("IdentityManager deployed at: ", address(identityManager));

        return identityManager;
    }
}
