// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { CrossRouter } from "../../src/crosschain/gnosis/CrossRouter.sol";

contract DeployCrossChainGnosis is PRBTest {
    CrossRouter public crossRouter;

    address public YAHO = 0x32a791d0eB36a326Ec2F8Eb318d77EF5755D3401;
    address public LAYER_ZERO_MESSAGE_RELAYER = 0x78819c40a7959105255903ED322f3FC803Ad24b3;
    address public LAYER_ZERO_ADAPTER = 0x78819c40a7959105255903ED322f3FC803Ad24b3;
    address public STRATEGY_VAULT = 0x0000000000000000000000000000000000000000;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        crossRouter = new CrossRouter(YAHO, LAYER_ZERO_MESSAGE_RELAYER, LAYER_ZERO_ADAPTER, STRATEGY_VAULT);
        vm.stopBroadcast();
    }
}
