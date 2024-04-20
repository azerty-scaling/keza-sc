// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Yaru } from "hashi/packages/evm/contracts/Yaru.sol";
import { IHashi } from "hashi/packages/evm/contracts/interfaces/IHashi.sol";
import { LayerZeroAdapter } from "hashi/packages/evm/contracts/adapters/LayerZero/LayerZeroAdapter.sol";

contract DeployHashiArbitrum is PRBTest {
    Yaru public yaru;
    LayerZeroAdapter public layerZeroAdapter;

    address public yahoAddress = 0x32a791d0eB36a326Ec2F8Eb318d77EF5755D3401;
    address public gnosisLayerZeroRelayerAddress = 0x78819c40a7959105255903ED322f3FC803Ad24b3;
    uint256 public arbitrumChainId = 42_161;
    uint256 public gnosisChainId = 100;
    uint256 public arbitrumSepoliaL2ChainId = 421_614;
    address public layerZeroArbitrumEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    uint16 public layerZeroArbitrumEndpointId = 110;
    address public layerZeroGnosisEndpoint = 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4;
    uint16 public layerZeroGnosisEndpointId = 145;
    address public hashiAddressGnosis = 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4;
    address public hashiAddressArbitrum = 0x3c2269811836af69497E5F486A85D7316753cf62;

    function run() public {
        vm.startBroadcast(vm.envUint("TEST_PRIVATE_KEY"));
        yaru = new Yaru(IHashi(hashiAddressArbitrum), yahoAddress, gnosisChainId);
        layerZeroAdapter = new LayerZeroAdapter(
            gnosisChainId, gnosisLayerZeroRelayerAddress, layerZeroArbitrumEndpoint, layerZeroGnosisEndpointId
        );

        vm.stopBroadcast();
    }
}
