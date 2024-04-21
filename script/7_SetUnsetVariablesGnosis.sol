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

    address public CREDIT_MODULE = 0x6fD4e7f1A4BD425C540243499585c19A9440791A;
    address public LENDING_POOL = 0xA1B51a4524811790C032Ae62b4e65FE67D8C23a7;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        ILendingPool(LENDING_POOL).setCreditModule(address(CREDIT_MODULE));

        vm.stopBroadcast();
    }
}
