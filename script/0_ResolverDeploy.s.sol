// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Resolver } from "../src/sign_resolver/Resolver.sol";

contract Deploy is PRBTest {
    Resolver public resolver;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));

        resolver = new Resolver();

        vm.stopBroadcast();
    }
}
