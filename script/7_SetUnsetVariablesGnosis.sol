// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Resolver } from "../src/sign_resolver/Resolver.sol";
import { CreditModule } from "../src/CreditModule.sol";
import { LendingPool } from "../src/LendingPool.sol";

interface ILendingPool {
    function setCreditModule(address creditModule) external;
}

contract Deploy is PRBTest {
    CreditModule public creditModule;
    LendingPool public lendingPool;

    address public CREDIT_MODULE = 0x5DEb5F4c0914dA54AcD1039e9406CF4fFBC26982;
    address public LENDING_POOL = 0x8A56A52Fc09b6F4a884191d560e8764b0C5F9363;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        ILendingPool(LENDING_POOL).setCreditModule(address(CREDIT_MODULE));

        vm.stopBroadcast();
    }
}
