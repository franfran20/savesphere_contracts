// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {TargetDrivenSave} from "../../src/SaveSphere/TargetDrivenSave.sol";
import {DeployTargetDrivenSave} from "../../script/DeploySaveContracts.s.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MockMTRG} from "../../src/test/MockMTRG.sol";

abstract contract TargetDrivenSaveBase is Test {
    // USERS
    address USER_ONE = makeAddr("USER_ONE");
    address USER_TWO = makeAddr("USER_TWO");
    address USER_THREE = makeAddr("USER_THREE");

    uint256 SAVE_START_AMOUNT = 15e18;
    string REASON = "I LOVE EGGS";
    uint256 TARGET_AMOUNT = 25e18;
    uint256 SAVE_TIME = 2 hours;

    uint256 TOP_UP_AMOUNT = 7e18;
    uint256 COMPLETE_TOP_UP_AMOUNT = 10e18;

    TargetDrivenSave targetDrivenSave;
    MockMTRG MTRG;
    address mtrgAddress;

    function setUp() public {
        DeployTargetDrivenSave deployTargetDrivenSave = new DeployTargetDrivenSave();
        (targetDrivenSave, mtrgAddress) = deployTargetDrivenSave.run();
        MTRG = MockMTRG(mtrgAddress);
    }

    function _approveMTRG(address _user, uint256 _amount) internal {
        vm.startPrank(_user);
        MTRG.mintToUser(_user, _amount);
        MTRG.approve(address(targetDrivenSave), _amount);
        vm.stopPrank();
    }

    function _createTargetDrivenSaveBothConditions(address _user) internal {
        _approveMTRG(_user, SAVE_START_AMOUNT);
        vm.startPrank(_user);
        targetDrivenSave.createTargetDrivenSave({
            _reason: REASON,
            _amount: SAVE_START_AMOUNT,
            _targetAmount: TARGET_AMOUNT,
            _time: SAVE_TIME
        });
        vm.stopPrank();
    }

    function _createTargetDrivenSaveAmountConditon(address _user) internal {
        _approveMTRG(_user, SAVE_START_AMOUNT);
        vm.startPrank(_user);
        targetDrivenSave.createTargetDrivenSave({
            _reason: REASON,
            _amount: SAVE_START_AMOUNT,
            _targetAmount: TARGET_AMOUNT,
            _time: 0
        });
        vm.stopPrank();
    }

    function _createTargetDrivenSaveTimeConditon(address _user) internal {
        _approveMTRG(_user, SAVE_START_AMOUNT);
        vm.startPrank(_user);
        targetDrivenSave.createTargetDrivenSave({
            _reason: REASON,
            _amount: SAVE_START_AMOUNT,
            _targetAmount: 0,
            _time: SAVE_TIME
        });
        vm.stopPrank();
    }

    function _topUpTargetDrivenSave(address _user, uint256 _saveId, uint256 _amount) internal {
        _approveMTRG(_user, _amount);
        vm.startPrank(_user);
        targetDrivenSave.topUpTargetDrivenSave({_saveId: _saveId, _amount: _amount});
        vm.stopPrank();
    }
}
