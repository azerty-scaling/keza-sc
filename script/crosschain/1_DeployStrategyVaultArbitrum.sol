// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { CrossRouter } from "../../src/crosschain/gnosis/CrossRouter.sol";
import { StrategyVault } from "../../src/crosschain/arbitrum/StrategyVault.sol";

contract DeployCrossChainGnosis is PRBTest {
    StrategyVault public strategyVault;

    address public WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address public AARBWSTETH = 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf;
    address public Yaru = 0x32a791d0eB36a326Ec2F8Eb318d77EF5755D3401;
    address public CROSS_ROUTER = 0x0000000000000000000000000000000000000000;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        strategyVault = new StrategyVault(EURe, "NEXTPAY", "npwstETH", Yaru, CROSS_ROUTER, AARBWSTETH);
        vm.stopBroadcast();
    }
}
