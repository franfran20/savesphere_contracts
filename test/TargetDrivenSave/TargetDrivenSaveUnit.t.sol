// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {console} from "forge-std/Test.sol";
import {TargetDrivenSave} from "../../src/SaveSphere/TargetDrivenSave.sol";
import {TargetDrivenSaveBase} from "./TargetDrivenSaveBase.t.sol";

contract GroupSaveUnitTest is TargetDrivenSaveBase {
    ///////////////////////////////////////////
    ///////// CREATE TARGET DRIVEN SAVE ///////
    ///////////////////////////////////////////

    function testCreateTargetDrivenSave__TransfersMTRGSuccesfully() public {
        _approveMTRG(USER_ONE, SAVE_START_AMOUNT);

        vm.startPrank(USER_ONE);
        targetDrivenSave.createTargetDrivenSave({
            _reason: REASON,
            _amount: SAVE_START_AMOUNT,
            _targetAmount: TARGET_AMOUNT,
            _time: SAVE_TIME
        });
        vm.stopPrank();

        assertEq(MTRG.balanceOf(address(targetDrivenSave)), SAVE_START_AMOUNT);
    }

    function testCreateTargetDrivenSave__UpdatesTheSavingsDetails__OnBothConditionSet() public {
        _approveMTRG(USER_ONE, SAVE_START_AMOUNT);

        vm.startPrank(USER_ONE);
        targetDrivenSave.createTargetDrivenSave({
            _reason: REASON,
            _amount: SAVE_START_AMOUNT,
            _targetAmount: TARGET_AMOUNT,
            _time: SAVE_TIME
        });
        vm.stopPrank();

        uint256 saveId = 1;

        TargetDrivenSave.TargetDrivenSavings memory targetDrivenSavingsOne =
            targetDrivenSave.getUserTargetDrivenSaving(USER_ONE, saveId);

        assertEq(targetDrivenSavingsOne.saveId, saveId);
        assertEq(targetDrivenSavingsOne.reason, REASON);
        assertEq(targetDrivenSavingsOne.amount, SAVE_START_AMOUNT);
        assertEq(targetDrivenSavingsOne.targetAmount, TARGET_AMOUNT);
        assertEq(targetDrivenSavingsOne.startTime, block.timestamp);
        assertEq(targetDrivenSavingsOne.stopTime, block.timestamp + SAVE_TIME);
        assertEq(targetDrivenSavingsOne.completed, false);
    }

    function testCreateTargetDrivenSave__UpdatesTheSavingsDetails__OnOnlyTimeConditionSet() public {
        _approveMTRG(USER_ONE, SAVE_START_AMOUNT);

        vm.startPrank(USER_ONE);
        targetDrivenSave.createTargetDrivenSave({
            _reason: REASON,
            _amount: SAVE_START_AMOUNT,
            _targetAmount: 0,
            _time: SAVE_TIME
        });
        vm.stopPrank();

        uint256 saveId = 1;

        TargetDrivenSave.TargetDrivenSavings memory targetDrivenSavingsOne =
            targetDrivenSave.getUserTargetDrivenSaving(USER_ONE, saveId);

        assertEq(targetDrivenSavingsOne.saveId, saveId);
        assertEq(targetDrivenSavingsOne.reason, REASON);
        assertEq(targetDrivenSavingsOne.amount, SAVE_START_AMOUNT);
        assertEq(targetDrivenSavingsOne.targetAmount, 0);
        assertEq(targetDrivenSavingsOne.startTime, block.timestamp);
        assertEq(targetDrivenSavingsOne.stopTime, block.timestamp + SAVE_TIME);
        assertEq(targetDrivenSavingsOne.completed, false);
    }

    function testCreateTargetDrivenSave__UpdatesTheSavingsDetails__OnOnlyTargetAmountConditionSet() public {
        _approveMTRG(USER_ONE, SAVE_START_AMOUNT);

        vm.startPrank(USER_ONE);
        targetDrivenSave.createTargetDrivenSave({
            _reason: REASON,
            _amount: SAVE_START_AMOUNT,
            _targetAmount: TARGET_AMOUNT,
            _time: 0
        });
        vm.stopPrank();

        uint256 saveId = 1;

        TargetDrivenSave.TargetDrivenSavings memory targetDrivenSavingsOne =
            targetDrivenSave.getUserTargetDrivenSaving(USER_ONE, saveId);

        assertEq(targetDrivenSavingsOne.saveId, saveId);
        assertEq(targetDrivenSavingsOne.reason, REASON);
        assertEq(targetDrivenSavingsOne.amount, SAVE_START_AMOUNT);
        assertEq(targetDrivenSavingsOne.targetAmount, TARGET_AMOUNT);
        assertEq(targetDrivenSavingsOne.startTime, block.timestamp);
        assertEq(targetDrivenSavingsOne.stopTime, 0);
        assertEq(targetDrivenSavingsOne.completed, false);
    }

    function testCreateTargetDrivenSave__Reverts__IfTheSaveStartAmountIsZero() public {
        _approveMTRG(USER_ONE, SAVE_START_AMOUNT);

        vm.startPrank(USER_ONE);
        vm.expectRevert(TargetDrivenSave.TargetDrivenSave__AmountCannnotBeZero.selector);
        targetDrivenSave.createTargetDrivenSave({
            _reason: REASON,
            _amount: 0,
            _targetAmount: TARGET_AMOUNT,
            _time: SAVE_TIME
        });
        vm.stopPrank();
    }

    function testCreateTargetDrivenSave__Reverts__IfNoSaveConditionIsSet() public {
        _approveMTRG(USER_ONE, SAVE_START_AMOUNT);

        vm.startPrank(USER_ONE);
        vm.expectRevert(TargetDrivenSave.TargetDrivenSave__AtLeastOneConditionMustBeSet.selector);
        targetDrivenSave.createTargetDrivenSave({
            _reason: REASON,
            _amount: SAVE_START_AMOUNT,
            _targetAmount: 0,
            _time: 0
        });
        vm.stopPrank();
    }

    ///////////////////////////////////////////
    ///////// TOP UP TARGET DRIVEN SAVE ///////
    ///////////////////////////////////////////

    // topUpTargetDrivenSave(uint256 _saveId, uint256 _amount)

    function testTopUpTargetDrivenSave__TransfersMTRGSuccefully() public {
        _createTargetDrivenSaveBothConditions(USER_ONE);

        uint256 saveId = 1;

        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);
        vm.startPrank(USER_ONE);
        targetDrivenSave.topUpTargetDrivenSave({_saveId: saveId, _amount: TOP_UP_AMOUNT});
        vm.stopPrank();

        assertEq(MTRG.balanceOf(address(targetDrivenSave)), SAVE_START_AMOUNT + TOP_UP_AMOUNT);
    }

    function testTopUpTargetDrivenSave__UpdatesTheUserSavingsDetailsForTheSaveID() public {
        _createTargetDrivenSaveBothConditions(USER_ONE);

        uint256 saveId = 1;

        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);
        vm.startPrank(USER_ONE);
        targetDrivenSave.topUpTargetDrivenSave({_saveId: saveId, _amount: TOP_UP_AMOUNT});
        vm.stopPrank();

        TargetDrivenSave.TargetDrivenSavings memory targetDrivenSavingsOne =
            targetDrivenSave.getUserTargetDrivenSaving(USER_ONE, saveId);

        assertEq(targetDrivenSavingsOne.amount, SAVE_START_AMOUNT + TOP_UP_AMOUNT);
    }

    function testTopUpTargetDrivenSave__Reverts__IfAmountIsZero() public {
        _createTargetDrivenSaveBothConditions(USER_ONE);

        uint256 saveId = 1;

        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);

        vm.startPrank(USER_ONE);
        vm.expectRevert(TargetDrivenSave.TargetDrivenSave__AmountCannnotBeZero.selector);
        targetDrivenSave.topUpTargetDrivenSave({_saveId: saveId, _amount: 0});
        vm.stopPrank();
    }

    function testTopUpTargetDrivenSave__Reverts__IfUserSaveIdDoesNotExist() public {
        _createTargetDrivenSaveBothConditions(USER_ONE);

        uint256 nonExistentSaveId = 10;

        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);

        vm.startPrank(USER_ONE);
        vm.expectRevert(TargetDrivenSave.TargetDrivenSave__SaveDoesNotExist.selector);
        targetDrivenSave.topUpTargetDrivenSave({_saveId: nonExistentSaveId, _amount: TOP_UP_AMOUNT});
        vm.stopPrank();
    }

    function testTopUpTargetDrivenSave__Reverts__IfTheSaveIsAlreadyCompleted() public {
        uint256 saveId = 1;

        _createTargetDrivenSaveBothConditions(USER_ONE);
        _topUpTargetDrivenSave(USER_ONE, saveId, TOP_UP_AMOUNT * 2);

        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);

        vm.startPrank(USER_ONE);

        vm.warp(block.timestamp + SAVE_TIME + 1);
        targetDrivenSave.unlockTargetDrivenSave(saveId);

        vm.expectRevert(TargetDrivenSave.TargetDrivenSave__SaveAlreadyUnlocked.selector);
        targetDrivenSave.topUpTargetDrivenSave({_saveId: saveId, _amount: TOP_UP_AMOUNT});

        vm.stopPrank();
    }

    ///////////////////////////////////////////
    ///////// UNLOCK TARGET DRIVEN SAVE ///////
    ///////////////////////////////////////////

    // unlockTargetDrivenSave

    function testUnlockTargetDrivenSave__TransfersUsersMTRGSuccesfully() public {
        uint256 saveId = 1;

        _createTargetDrivenSaveBothConditions(USER_ONE);
        _topUpTargetDrivenSave(USER_ONE, saveId, COMPLETE_TOP_UP_AMOUNT);

        vm.warp(block.timestamp + SAVE_TIME + 1);

        vm.startPrank(USER_ONE);
        targetDrivenSave.unlockTargetDrivenSave({_saveId: saveId});
        vm.stopPrank();

        assertEq(MTRG.balanceOf(USER_ONE), SAVE_START_AMOUNT + COMPLETE_TOP_UP_AMOUNT);
    }

    function testUnlockTargetDrivenSave__UpdatesTheUserSaveIdCompletedtate() public {
        uint256 saveId = 1;

        _createTargetDrivenSaveBothConditions(USER_ONE);
        _topUpTargetDrivenSave(USER_ONE, saveId, COMPLETE_TOP_UP_AMOUNT);

        vm.warp(block.timestamp + SAVE_TIME + 1);

        vm.startPrank(USER_ONE);
        targetDrivenSave.unlockTargetDrivenSave({_saveId: saveId});
        vm.stopPrank();

        TargetDrivenSave.TargetDrivenSavings memory targetDrivenSavingsOne =
            targetDrivenSave.getUserTargetDrivenSaving(USER_ONE, saveId);

        assertEq(targetDrivenSavingsOne.completed, true);
    }

    function testUnlockTargetDrivenSave__Reverts__IfTheSaveUserSaveIdDoesNotexist() public {
        uint256 saveId = 1;

        _createTargetDrivenSaveBothConditions(USER_ONE);
        _topUpTargetDrivenSave(USER_ONE, saveId, COMPLETE_TOP_UP_AMOUNT);

        vm.warp(block.timestamp + SAVE_TIME + 1);

        uint256 nonExistentId = 2;

        vm.startPrank(USER_ONE);
        vm.expectRevert(TargetDrivenSave.TargetDrivenSave__SaveDoesNotExist.selector);
        targetDrivenSave.unlockTargetDrivenSave({_saveId: nonExistentId});
        vm.stopPrank();
    }

    function testUnlockTargetDrivenSave__Reverts__IfTheSaveHasAlreadyBeenUnlocked() public {
        uint256 saveId = 1;

        _createTargetDrivenSaveBothConditions(USER_ONE);
        _topUpTargetDrivenSave(USER_ONE, saveId, COMPLETE_TOP_UP_AMOUNT);

        vm.warp(block.timestamp + SAVE_TIME + 1);

        vm.startPrank(USER_ONE);
        targetDrivenSave.unlockTargetDrivenSave({_saveId: saveId});

        vm.expectRevert(TargetDrivenSave.TargetDrivenSave__SaveAlreadyUnlocked.selector);
        targetDrivenSave.unlockTargetDrivenSave({_saveId: saveId});
        vm.stopPrank();
    }

    function testUnlockTargetDrivenSave__Reverts__IfTheTargetAmountHasNotBeenMet() public {
        uint256 saveId = 1;

        _createTargetDrivenSaveBothConditions(USER_ONE);

        vm.warp(block.timestamp + SAVE_TIME + 1);

        vm.startPrank(USER_ONE);

        vm.expectRevert(TargetDrivenSave.TargetDrivenSave__AmountTargetConditionNotSatisfied.selector);
        targetDrivenSave.unlockTargetDrivenSave({_saveId: saveId});
        vm.stopPrank();
    }

    function testUnlockTargetDrivenSave__Reverts__IfTheTimetHasNotBeenMet() public {
        uint256 saveId = 1;

        _createTargetDrivenSaveBothConditions(USER_ONE);

        _topUpTargetDrivenSave(USER_ONE, saveId, COMPLETE_TOP_UP_AMOUNT);

        vm.startPrank(USER_ONE);

        vm.expectRevert(TargetDrivenSave.TargetDrivenSave__TimeConditionNotSatisfied.selector);
        targetDrivenSave.unlockTargetDrivenSave({_saveId: saveId});
        vm.stopPrank();
    }
}
