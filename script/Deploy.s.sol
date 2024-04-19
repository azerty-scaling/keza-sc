// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { CreditModule } from "../src/CreditModule.sol";
import { LendingPoolMock } from "../src/LendingPoolMock.sol";

contract Deploy is PRBTest {
    CreditModule public creditModule;
    LendingPoolMock public lendingPool;

    address public oracleStETH = 0x229e486Ee0D35b7A9f668d10a1e6029eEE6B77E0;
    address public oracleEURe = 0xab70BCB260073d036d1660201e9d5405F5829b7a;
    address public stETH = 0xaf204776c7245bF4147c2612BF6e5972Ee483701;
    address public EURe = 0xcB444e90D8198415266c6a2724b7900fb12FC56E;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        eureVault = new EUReVault(EURe, "AZERTY MARKETS", "azEURe", 3 * 1e18, aEURe);
        creditModule = new CreditModule(oracleDAI, oracleEURe, sDAI, EURe);
        creditModule.setEureVault(address(eureVault));
        eureVault.setCreditModule(address(creditModule));
        vm.stopBroadcast();
    }
}
