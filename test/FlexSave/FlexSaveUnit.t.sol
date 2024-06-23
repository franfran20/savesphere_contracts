// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {console} from "forge-std/Test.sol";
import {FlexSave} from "../../src/SaveSphere/FlexSave.sol";
import {FlexSaveBaseTest} from "./FlexSaveBase.t.sol";

contract FlexSaveUnitTest is FlexSaveBaseTest {
    //////////////////////////////////////////
    /////////////// START SAVE ///////////////
    //////////////////////////////////////////

    function testStartSave__Reverts__IfAmountIsZero() public {
        _approveMTRG(USER_ONE, START_SAVE_AMOUNT);

        vm.startPrank(USER_ONE);
        vm.expectRevert(FlexSave.FlexSave__AmountCannotBeZero.selector);
        flexSave.startSave({_amount: 0, _time: ONE_HOUR, _reason: REASON});
        vm.stopPrank();
    }

    function testStartSave__Reverts__IfTimeIsZero() public {
        _approveMTRG(USER_ONE, START_SAVE_AMOUNT);

        vm.startPrank(USER_ONE);
        vm.expectRevert(FlexSave.FlexSave__TimeCannotBeZero.selector);
        flexSave.startSave({_amount: START_SAVE_AMOUNT, _time: 0, _reason: REASON});
        vm.stopPrank();
    }

    function testStartSave__Reverts__IfUserAlreadyHasExistingSave() public {
        _approveMTRG(USER_ONE, START_SAVE_AMOUNT * 2);

        vm.startPrank(USER_ONE);
        flexSave.startSave({_amount: START_SAVE_AMOUNT, _time: ONE_HOUR, _reason: REASON});

        vm.expectRevert(FlexSave.FlexSave__AlreadyHasActiveSavings.selector);
        flexSave.startSave({_amount: START_SAVE_AMOUNT, _time: ONE_HOUR, _reason: REASON});
        vm.stopPrank();
    }

    function testStartSave__UpdatesTopLevelParams() public {
        _approveMTRG(USER_ONE, START_SAVE_AMOUNT);

        vm.startPrank(USER_ONE);
        flexSave.startSave({_amount: START_SAVE_AMOUNT, _time: ONE_HOUR, _reason: REASON});
        vm.stopPrank();

        FlexSave.TopLevelSavingsDetails memory topLevelSavingsDetails = flexSave.getTopLevelSavingsDetails();

        assertEq(topLevelSavingsDetails.totalAmountSaved, START_SAVE_AMOUNT);
        assertEq(topLevelSavingsDetails.possibleSavingTime, ONE_HOUR);
        assertEq(topLevelSavingsDetails.totalSavers, 1);
    }

    function testStartSave__UpdatesUsersSavingsDetails() public {
        _approveMTRG(USER_ONE, START_SAVE_AMOUNT);

        vm.startPrank(USER_ONE);
        flexSave.startSave({_amount: START_SAVE_AMOUNT, _time: ONE_HOUR, _reason: REASON});
        vm.stopPrank();

        FlexSave.UserSavings memory usersSavings = flexSave.getUserSavings(USER_ONE);

        assertEq(usersSavings.reason, REASON);
        assertEq(usersSavings.amount, START_SAVE_AMOUNT);
        assertEq(usersSavings.startTime, block.timestamp);
        assertEq(usersSavings.startTime, block.timestamp);
        assertEq(usersSavings.stopTime, block.timestamp + ONE_HOUR);
        assertEq(usersSavings.status, true);
    }

    function testStartSave__TransfersMTRGFromUserSuccesfully() public {
        _approveMTRG(USER_ONE, START_SAVE_AMOUNT);

        vm.startPrank(USER_ONE);
        flexSave.startSave({_amount: START_SAVE_AMOUNT, _time: ONE_HOUR, _reason: REASON});
        vm.stopPrank();

        assertEq(MTRG.balanceOf(address(flexSave)), START_SAVE_AMOUNT);
    }

    //////////////////////////////////////////
    /////////////// TOP UP SAVE ///////////////
    //////////////////////////////////////////

    function testTopUpSave__Reverts__IfTheUserHasNoExistingSavings() public {
        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);

        vm.startPrank(USER_ONE);
        vm.expectRevert(FlexSave.FlexSave__NoActiveSavings.selector);
        flexSave.topUpSave({_amount: TOP_UP_AMOUNT, _time: ONE_HOUR});
        vm.stopPrank();
    }

    function testTopUpSave__Reverts__IfTheUserSaveTimeHasEnded() public {
        _startSave(USER_ONE, START_SAVE_AMOUNT, ONE_HOUR);
        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);

        vm.warp(block.timestamp + ONE_HOUR + 1);

        vm.startPrank(USER_ONE);
        vm.expectRevert(FlexSave.FlexSave__SavingTimeCompletedAlready.selector);
        flexSave.topUpSave({_amount: TOP_UP_AMOUNT, _time: ONE_HOUR});
        vm.stopPrank();
    }

    function testTopUpSave__Reverts__IfTheTopUpAmountIsZero() public {
        _startSave(USER_ONE, START_SAVE_AMOUNT, ONE_HOUR);
        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);

        vm.warp(block.timestamp + ONE_HOUR + 1);

        vm.startPrank(USER_ONE);
        vm.expectRevert(FlexSave.FlexSave__AmountCannotBeZero.selector);
        flexSave.topUpSave({_amount: 0, _time: ONE_HOUR});
        vm.stopPrank();
    }

    function testTopUpSave__TransfersMTRGFromUserSuccessfully() public {
        _startSave(USER_ONE, START_SAVE_AMOUNT, ONE_HOUR);
        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);

        vm.startPrank(USER_ONE);
        flexSave.topUpSave({_amount: TOP_UP_AMOUNT, _time: 0});
        vm.stopPrank();

        assertEq(MTRG.balanceOf(address(flexSave)), START_SAVE_AMOUNT + TOP_UP_AMOUNT);
    }

    function testTopUpSave__UpdatesTopLevelAndUserSavingDetails__WithNoTimeAttached() public {
        _startSave(USER_ONE, START_SAVE_AMOUNT, ONE_HOUR);
        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);

        vm.startPrank(USER_ONE);
        flexSave.topUpSave({_amount: TOP_UP_AMOUNT, _time: 0});
        vm.stopPrank();

        FlexSave.TopLevelSavingsDetails memory topLevelSavingsDetails = flexSave.getTopLevelSavingsDetails();
        FlexSave.UserSavings memory usersSavings = flexSave.getUserSavings(USER_ONE);

        assertEq(topLevelSavingsDetails.totalAmountSaved, START_SAVE_AMOUNT + TOP_UP_AMOUNT);
        assertEq(topLevelSavingsDetails.possibleSavingTime, ONE_HOUR);

        assertEq(usersSavings.amount, START_SAVE_AMOUNT + TOP_UP_AMOUNT);
        assertEq(usersSavings.stopTime, block.timestamp + ONE_HOUR);
    }

    function testTopUpSave__UpdatesTopLevelAndUserSavingDetails__WithTimeAttached() public {
        _startSave(USER_ONE, START_SAVE_AMOUNT, ONE_HOUR);
        _approveMTRG(USER_ONE, TOP_UP_AMOUNT);

        vm.startPrank(USER_ONE);
        flexSave.topUpSave({_amount: TOP_UP_AMOUNT, _time: ONE_HOUR});
        vm.stopPrank();

        FlexSave.TopLevelSavingsDetails memory topLevelSavingsDetails = flexSave.getTopLevelSavingsDetails();
        FlexSave.UserSavings memory usersSavings = flexSave.getUserSavings(USER_ONE);

        assertEq(topLevelSavingsDetails.totalAmountSaved, START_SAVE_AMOUNT + TOP_UP_AMOUNT);
        assertEq(topLevelSavingsDetails.possibleSavingTime, TWO_HOURS);

        assertEq(usersSavings.amount, START_SAVE_AMOUNT + TOP_UP_AMOUNT);
        assertEq(usersSavings.stopTime, block.timestamp + TWO_HOURS);
    }

    //////////////////////////////////////////
    /////////////// CLAIM SAVE ///////////////
    //////////////////////////////////////////

    function testClaimSave__Reverts__IfUserHasNoActiveSave() public {
        vm.startPrank(USER_ONE);
        vm.expectRevert(FlexSave.FlexSave__NoActiveSavings.selector);
        flexSave.claimSavings();
        vm.stopPrank();
    }

    function testClaimSaveWithDefault__CollectsDefaultFeeFromSaverOnSaveBreak__AndReturnsSavingsLeft() public {
        _startSave(USER_ONE, START_SAVE_AMOUNT, ONE_HOUR);

        // not up to save time
        vm.warp(block.timestamp + THIRTY_MINS);

        vm.startPrank(USER_ONE);
        flexSave.claimSavings();
        vm.stopPrank();

        assertEq(MTRG.balanceOf(address(flexSave)), _getFeeCollected(START_SAVE_AMOUNT));
        assertEq(MTRG.balanceOf(address(USER_ONE)), _getSaveReturnedAfterFee(START_SAVE_AMOUNT));
    }

    function testClaimSaveWithDefault__UpdatesTheTopLevelSavingsDetails() public {
        _startSave(USER_ONE, START_SAVE_AMOUNT, ONE_HOUR);
        _startSave(USER_TWO, START_SAVE_AMOUNT, TWO_HOURS);

        // not up to save time
        vm.warp(block.timestamp + THIRTY_MINS);

        vm.startPrank(USER_ONE);
        flexSave.claimSavings();
        vm.stopPrank();

        FlexSave.TopLevelSavingsDetails memory topLevelSavingsDetails = flexSave.getTopLevelSavingsDetails();

        assertEq(topLevelSavingsDetails.totalAmountSaved, START_SAVE_AMOUNT);
        assertEq(topLevelSavingsDetails.possibleSavingTime, TWO_HOURS);
        assertEq(topLevelSavingsDetails.totalSavers, 1);
        assertEq(topLevelSavingsDetails.defaultPool, _getFeeCollected(START_SAVE_AMOUNT));
    }

    function testClaimSaveWithDefault__UpdatesTheUserSavingsDetails() public {
        _startSave(USER_ONE, START_SAVE_AMOUNT, ONE_HOUR);

        // not up to save time
        vm.warp(block.timestamp + THIRTY_MINS);

        vm.startPrank(USER_ONE);
        flexSave.claimSavings();
        vm.stopPrank();

        FlexSave.UserSavings memory usersSavings = flexSave.getUserSavings(USER_ONE);

        assertEq(usersSavings.reason, "");
        assertEq(usersSavings.amount, 0);
        assertEq(usersSavings.startTime, 0);
        assertEq(usersSavings.stopTime, 0);
        assertEq(usersSavings.status, false);
    }

    function testClaimSave__GetUserEndInterest__ReturnsZeroIsUserHasNoSavings() public view {
        uint256 userInterestShare = flexSave.getUserEndInterest(USER_ONE);

        assertEq(userInterestShare, 0);
    }

    function testClaimSave__GetUserEndInterest__ReturnsZeroIfDefaultPoolIsEmpty() public {
        _startSave(USER_ONE, START_SAVE_AMOUNT, ONE_HOUR);
        _startSave(USER_TWO, START_SAVE_AMOUNT, ONE_HOUR);

        vm.warp(block.timestamp + ONE_HOUR + 1);

        uint256 userOneInterestShare = flexSave.getUserEndInterest(USER_ONE);
        uint256 userTwoInterestShare = flexSave.getUserEndInterest(USER_TWO);

        assertEq(userOneInterestShare, 0);
        assertEq(userTwoInterestShare, 0);
    }

    // can refactor this test to be more flexible and in depth based off the math in docs!
    function testClaimSave__GetUserEndInterest__SharesInterestBasedOnTimeAndAmount() public {
        _multipleSaveSetUp();

        uint256 userOneInterestShare = flexSave.getUserEndInterest(USER_ONE);
        uint256 userTwoInterestShare = flexSave.getUserEndInterest(USER_TWO);

        console.log("User one Interest Share: ", userOneInterestShare);
        console.log("User two Interest Share: ", userTwoInterestShare);
    }

    // can refactor this test to be more flexible and in depth!
    function testClaimSaveWithInterest__TransfersTheUsersSavingsWithInterest__BasedOffTheTimeSavedAndAmount() public {
        _multipleSaveSetUp();

        uint256 userOneInterestShare = flexSave.getUserEndInterest(USER_ONE);
        vm.startPrank(USER_ONE);
        flexSave.claimSavings();
        vm.stopPrank();

        uint256 userTwoInterestShare = flexSave.getUserEndInterest(USER_TWO);
        vm.startPrank(USER_TWO);
        flexSave.claimSavings();
        vm.stopPrank();

        console.log(userOneInterestShare, userTwoInterestShare);

        assertEq(MTRG.balanceOf(USER_ONE), USER_ONE_SAVE_AMOUNT + userOneInterestShare);
        assertEq(MTRG.balanceOf(USER_TWO), USER_TWO_SAVE_AMOUNT + userTwoInterestShare);
    }

    function testClaimSaveWithInterest__UpdatesTheTopLevelSavingsDetails() public {
        _multipleSaveSetUp();

        vm.startPrank(USER_ONE);
        flexSave.claimSavings();
        vm.stopPrank();

        uint256 userTwoInterestShare = flexSave.getUserEndInterest(USER_TWO);
        FlexSave.TopLevelSavingsDetails memory topLevelSavingsDetails = flexSave.getTopLevelSavingsDetails();

        assertEq(topLevelSavingsDetails.totalAmountSaved, USER_TWO_SAVE_AMOUNT);
        assertEq(topLevelSavingsDetails.completedTimeSaved, ONE_HOUR);
        assertEq(topLevelSavingsDetails.possibleSavingTime, TWO_HOURS);
        assertEq(topLevelSavingsDetails.totalSavers, 1);
        assertEq(topLevelSavingsDetails.defaultPool, userTwoInterestShare);
    }

    function testClaimSaveWithInterest__UpdatesTheUserSavingsDetails() public {
        _multipleSaveSetUp();

        vm.startPrank(USER_ONE);
        flexSave.claimSavings();
        vm.stopPrank();

        FlexSave.UserSavings memory usersSavings = flexSave.getUserSavings(USER_ONE);

        assertEq(usersSavings.reason, "");
        assertEq(usersSavings.amount, 0);
        assertEq(usersSavings.startTime, 0);
        assertEq(usersSavings.stopTime, 0);
        assertEq(usersSavings.status, false);
    }
}
