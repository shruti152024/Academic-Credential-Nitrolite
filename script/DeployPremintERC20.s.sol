// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {PremintERC20} from "../src/PremintERC20.sol";

contract DeployPremintERC20 is Script {
    function run() external {
        vm.startBroadcast();

        PremintERC20 token = new PremintERC20(
            "Nitrolite Token",
            "NIT",
            18,
            msg.sender,
            1000000 ether
        );

        vm.stopBroadcast();

        console.log("Token deployed at:", address(token));
    }
}
