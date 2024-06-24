// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";
import {MockMTRG} from "../src/test/MockMTRG.sol";

// Currently Deployed

// Testnet
// FlexSave -  0x9FAA0978666B45bACD623E1abD24EbC456bD018b
// GroupSave - 0xca19D52603977Aff02E3dF9d6844ABDED270dDf4
// TargetDrivenSave - 0x5490194Dff63994Ad35AF72a849049A2445AF7C1

contract HelperConfig is Script {
    uint256 constant DEFAULT_FEE_TESTNET = 10;
    uint256 constant DEFAULT_FEE_MAINNET = 10;

    address MTRG_TESTNET = 0x8A419Ef4941355476cf04933E90Bf3bbF2F73814;
    address MTRG_MAINNET = 0x228ebBeE999c6a7ad74A6130E81b12f9Fe237Ba3;

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint256 defaultFee;
        address MTRG;
    }

    constructor() {
        if (block.chainid == 82) {
            activeNetworkConfig = getMeterNetworkConfig();
        } else if (block.chainid == 83) {
            activeNetworkConfig = getMeterTestnetNetworkConfig();
        } else {
            activeNetworkConfig = getAnvilNetworkConfig();
        }
    }

    function getMeterNetworkConfig() private view returns (NetworkConfig memory) {
        return NetworkConfig({defaultFee: DEFAULT_FEE_MAINNET, MTRG: MTRG_MAINNET});
    }

    function getMeterTestnetNetworkConfig() private view returns (NetworkConfig memory) {
        return NetworkConfig({defaultFee: DEFAULT_FEE_TESTNET, MTRG: MTRG_TESTNET});
    }

    function getAnvilNetworkConfig() private returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockMTRG mockMTRG = new MockMTRG();
        vm.stopBroadcast();

        return NetworkConfig({defaultFee: DEFAULT_FEE_TESTNET, MTRG: address(mockMTRG)});
    }
}
