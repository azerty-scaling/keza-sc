// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { LayerZeroMessageRelay } from "hashi/packages/evm/contracts/adapters/LayerZero/LayerZeroMessageRelay.sol";
import { AllowanceOracle } from "../../src/crosschain/gnosis/AllowanceOracle.sol";

contract Deploy is PRBTest {
    AllowanceOracle public allowanceOracle;

    address public CREDIT_MODULE = 0x5DEb5F4c0914dA54AcD1039e9406CF4fFBC26982;
    address public CROSS_ROUTER = 0x7B72dF4B7FEaF1653224043d06d9067a77dab04D;
    address public OFFCHAIN_ALLOWANCE_ORACLE = 0xbCc802BFb35C4CDC9cA1B3e0bc0EbfEf7d0DcDb1;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        allowanceOracle = new AllowanceOracle(OFFCHAIN_ALLOWANCE_ORACLE, CREDIT_MODULE, CROSS_ROUTER);
        vm.stopBroadcast();
    }
}
