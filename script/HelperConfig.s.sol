// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";

// import {WorldIDIdentityManagerRouterMock} from "../test/Anvil/Unit/mocks/WorldIDIdentityManagerRouterMock.sol";

contract HelperConfig is Script {
    string appId = "app_staging_9e74e697f8ab2acdd8192776b90c6902";
    string actionId = "verify-entity";

    struct Config {
        string _appid;
        string _actionId;
        address _WorldcoinRouterAddress;
    }

    function getBaseSepoliaConfig() public view returns (Config memory) {
        Config memory BaseSepoliaConfig = Config({
            _appid: appId,
            _actionId: actionId,
            _WorldcoinRouterAddress: 0x42FF98C4E85212a5D31358ACbFe76a621b50fC02
        });
        return BaseSepoliaConfig;
    }

    function getAnvilConfig() public returns (Config memory) {
        console.log("testing on anvil");
        // WorldIDIdentityManagerRouterMock routerMock = new WorldIDIdentityManagerRouterMock();
        Config memory AnvilConfig = Config({_appid: appId, _actionId: actionId, _WorldcoinRouterAddress: address(0)});
        return AnvilConfig;
    }
}
