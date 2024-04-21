// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Resolver } from "../src/sign_resolver/Resolver.sol";
import { CreditModule } from "../src/CreditModule.sol";
import { LendingPool } from "../src/LendingPool.sol";

interface ICrossRouter {
    function setAllowanceOracle(address allowanceOracle) external;
}

contract Deploy is PRBTest {
    CreditModule public creditModule;
    LendingPool public lendingPool;

    address public CROSS_ROUTER = 0xa9ea2b38304C91e25c08fcFBCC3C0c548A62B205;
    address public ALLOWANCE_ORACLE = 0xB06D1bCe3689AB582f2d0bB274Ea7A8DCd4B0B1D;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        ICrossRouter(CROSS_ROUTER).setAllowanceOracle(address(ALLOWANCE_ORACLE));

        vm.stopBroadcast();
    }
}
