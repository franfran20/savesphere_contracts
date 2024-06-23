// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {FlexSave} from "../../src/SaveSphere/FlexSave.sol";
import {DeployFlexSave} from "../../script/DeploySaveContracts.s.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MockMTRG} from "../../src/test/MockMTRG.sol";

abstract contract FlexSaveBaseTest is Test {
    address mtrgAddress;
    address USER_ONE = makeAddr("USER_ONE");
    address USER_TWO = makeAddr("USER_TWO");
    address USER_THREE = makeAddr("USER_THREE");

    uint256 START_SAVE_AMOUNT = 20e18;
    uint256 TOP_UP_AMOUNT = 5e18;

    uint256 DEFAULT_FEE = 20;

    uint256 ONE_HOUR = 1 hours;
    uint256 TWO_HOURS = 2 hours;
    uint256 THIRTY_MINS = 30 minutes;

    string REASON = "I want to take care of the fammmmmm";

    uint256 USER_ONE_SAVE_AMOUNT = 20e18;
    uint256 USER_TWO_SAVE_AMOUNT = 15e18;
    uint256 USER_THREE_SAVE_AMOUNT = 40e18;

    FlexSave flexSave;
    MockMTRG MTRG;

    function setUp() public {
        DeployFlexSave deployFlexSave = new DeployFlexSave();
        (flexSave, mtrgAddress) = deployFlexSave.run();
        MTRG = MockMTRG(mtrgAddress);
    }

    // approves mtrg token to the flex save contract for a user
    function _approveMTRG(address _user, uint256 _amount) internal {
        vm.startPrank(_user);
        MTRG.mintToUser(_user, _amount);
        MTRG.approve(address(flexSave), _amount);
        vm.stopPrank();
    }

    // starts the flex save for a user
    function _startSave(address _user, uint256 _amount, uint256 _time) internal {
        _approveMTRG(_user, _amount);

        vm.startPrank(_user);
        flexSave.startSave(_amount, _time, REASON);
        vm.stopPrank();
    }

    // claims save for a user
    function _claimSave(address _user) internal {
        vm.startPrank(_user);
        flexSave.claimSavings();
        vm.stopPrank();
    }

    // multple save setup for interest pool generation for testing
    // can refactor this test process to be way better
    // revisit needed!
    function _multipleSaveSetUp() internal {
        _startSave(USER_ONE, USER_ONE_SAVE_AMOUNT, ONE_HOUR);
        _startSave(USER_TWO, USER_TWO_SAVE_AMOUNT, TWO_HOURS);
        _startSave(USER_THREE, USER_THREE_SAVE_AMOUNT, ONE_HOUR);

        vm.warp(block.timestamp + THIRTY_MINS);
        _claimSave(USER_THREE);

        vm.warp(block.timestamp + TWO_HOURS + 1);
    }

    // returns the default fee amount collected from an amount i.e default fee % of amount
    function _getFeeCollected(uint256 _amount) internal view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        return (DEFAULT_FEE * _amount) / 100;
    }

    // gets the amount left after the default fee has been taken
    function _getSaveReturnedAfterFee(uint256 _amount) internal view returns (uint256) {
        uint256 savigsBeforeDefaultFee = _amount;
        uint256 feeCollected = _getFeeCollected(savigsBeforeDefaultFee);

        return savigsBeforeDefaultFee - feeCollected;
    }
}
