// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { LayerZeroMessageRelay } from "hashi/packages/evm/contracts/adapters/LayerZero/LayerZeroMessageRelay.sol";
import { AllowanceOracle } from "../../src/crosschain/gnosis/AllowanceOracle.sol";

contract DeployCrossChainGnosis is PRBTest {
    AllowanceOracle public allowanceOracle;

    uint256 public arbitrumChainId = 42_161;
    uint256 public arbitrumSepoliaL2ChainId = 421_614;
    address public layerZeroArbitrumEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    uint16 public layerZeroArbitrumEndpointId = 110;
    address public layerZeroGnosisEndpoint = 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4;
    uint16 public layerZeroGnosisEndpointId = 145;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        //        allowanceOracle = new AllowanceOracle(address(0), address(0));
        //        layerZeroMessageRelay = new LayerZeroMessageRelay(
        //            address(yaho), arbitrumChainId, layerZeroGnosisEndpoint, layerZeroArbitrumEndpointId
        //        );

        vm.stopBroadcast();
    }
}
