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

    address public CROSS_ROUTER = 0x7B72dF4B7FEaF1653224043d06d9067a77dab04D;
    address public ALLOWANCE_ORACLE = 0x0B318B2CE4dd324e2AA74D2167046c58A9aE9321;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        ICrossRouter(CROSS_ROUTER).setAllowanceOracle(address(ALLOWANCE_ORACLE));

        vm.stopBroadcast();
    }
}
