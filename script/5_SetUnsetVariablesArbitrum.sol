// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Resolver } from "../src/sign_resolver/Resolver.sol";
import { CreditModule } from "../src/CreditModule.sol";
import { LendingPool } from "../src/LendingPool.sol";

interface IStrategyVault {
    function setCrossRouter(address crossRouter) external;
}

contract Deploy is PRBTest {
    CreditModule public creditModule;
    LendingPool public lendingPool;

    address public STRATEGY_VAULT = 0x0000000000000000000000000000000000000000;
    address public CROSS_ROUTER = 0x0000000000000000000000000000000000000000;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        IStrategyVault(STRATEGY_VAULT).setCrossRouter(address(CROSS_ROUTER));

        vm.stopBroadcast();
    }
}
