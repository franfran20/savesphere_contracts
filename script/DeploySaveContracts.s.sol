// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";

import {FlexSave} from "../src/SaveSphere/FlexSave.sol";
import {GroupSave} from "../src/SaveSphere/GroupSave.sol";
import {TargetDrivenSave} from "../src/SaveSphere/TargetDrivenSave.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

// FlexSave -  0x84988Ab4EEBd3760947501DBCa10E5926316E4CD
// GroupSave - 0x6bbD59dc7F8244eCE9c36Ab3Da98B04f90F64A0e
// TargetDrivenSave - 0xbCFe27905a7c510bf8339033D1627B7e2D02d802

contract DeployFlexSave is Script {
    function run() external returns (FlexSave, address) {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 defaultFee, address MTRG) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        FlexSave flexSave = new FlexSave(MTRG, defaultFee);
        vm.stopBroadcast();

        console.log("Deployed FlexSave To: ", address(flexSave));
        return (flexSave, MTRG);
    }
}

contract DeployGroupSave is Script {
    function run() external returns (GroupSave, address) {
        HelperConfig helperConfig = new HelperConfig();
        (, address MTRG) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        GroupSave groupsave = new GroupSave(MTRG);
        vm.stopBroadcast();

        console.log("Deployed Groupsave To: ", address(groupsave));
        return (groupsave, MTRG);
    }
}

contract DeployTargetDrivenSave is Script {
    function run() external returns (TargetDrivenSave, address) {
        HelperConfig helperConfig = new HelperConfig();
        (, address MTRG) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        TargetDrivenSave targetDrivenSave = new TargetDrivenSave(MTRG);
        vm.stopBroadcast();

        console.log("Deployed TargetDrivenSave To: ", address(targetDrivenSave));
        return (targetDrivenSave, MTRG);
    }
}
