// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { LayerZeroMessageRelay } from "hashi/packages/evm/contracts/adapters/LayerZero/LayerZeroMessageRelay.sol";
import { AllowanceOracle } from "../../src/crosschain/gnosis/AllowanceOracle.sol";

contract DeployAllowanceOracle is PRBTest {
    AllowanceOracle public allowanceOracle;

    address public CREDIT_MODULE = 0x0000000000000000000000000000000000000000;
    address public CROSS_ROUTER = 0x0000000000000000000000000000000000000000;
    address public OFFCHAIN_ALLOWANCE_ORACLE = 0xbCc802BFb35C4CDC9cA1B3e0bc0EbfEf7d0DcDb1;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        allowanceOracle = new AllowanceOracle(OFFCHAIN_ALLOWANCE_ORACLE, CREDIT_MODULE, CROSS_ROUTER);
        vm.stopBroadcast();
    }
}
