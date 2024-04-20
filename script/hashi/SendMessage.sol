// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Yaho } from "hashi/packages/evm/contracts/Yaho.sol";
import { Yaho } from "hashi/packages/evm/contracts/interfaces/IYaho.sol";
import { LayerZeroMessageRelay } from "hashi/packages/evm/contracts/adapters/LayerZero/LayerZeroMessageRelay.sol";
import { Message } from "hashi/packages/evm/contracts/interfaces/IMessage.sol";

//import {Yaho} from "../dependencies/hashi/packages/evm/contracts/Yaho.sol";
//import {LayerZeroMessageRelay} from
// "../dependencies/hashi/packages/evm/contracts/adapters/LayerZero/LayerZeroMessageRelay.sol";

contract SendMessage is PRBTest {
    //    Yaho public yaho;
    LayerZeroMessageRelay public layerZeroMessageRelay;

    uint256 public arbitrumChainId = 42_161;
    address yahoAddress = 0x32a791d0eB36a326Ec2F8Eb318d77EF5755D3401;
    uint256 public arbitrumSepoliaL2ChainId = 421_614;
    address public layerZeroArbitrumEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    uint16 public layerZeroArbitrumEndpointId = 110;
    address public layerZeroGnosisEndpoint = 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4;
    uint16 public layerZeroGnosisEndpointId = 145;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        Message[] memory messages = new Message[](1);
        bytes calldata_ = IERC20.encodeFunctionData("approve", parameters);
        IYaho(yahoAddress).dispatchMessagesToAdapters() layerZeroMessageRelay = new LayerZeroMessageRelay(
            address(yaho), arbitrumChainId, layerZeroGnosisEndpoint, layerZeroArbitrumEndpointId
        );

        vm.stopBroadcast();
    }
}
