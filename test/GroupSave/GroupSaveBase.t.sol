// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {GroupSave} from "../../src/SaveSphere/GroupSave.sol";
import {DeployGroupSave} from "../../script/DeploySaveContracts.s.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MockMTRG} from "../../src/test/MockMTRG.sol";

abstract contract GroupSaveBaseTest is Test {
    address mtrgAddress;

    uint256 GROUP_TOP_UP_AMOUNT = 10e18;

    // group creators
    address CREATOR_ONE = makeAddr("CREATOR_ONE");
    address CREATOR_TWO = makeAddr("CREATOR_TWO");

    // MEMBERS GORUP 1
    address USER_ONE = makeAddr("USER_ONE");
    address USER_TWO = makeAddr("USER_TWO");
    address USER_THREE = makeAddr("USER_THREE");
    address USER_FOUR = makeAddr("USER_FOUR");

    // MEMBERS GROUP 2
    address USER_FIVE = makeAddr("USER_FIVE");

    // Recipient Addresses
    address RECIPEINT_ONE = makeAddr("RECIPEINT_ONE");
    address RECIPEINT_TWO = makeAddr("RECIPEINT_TWO");
    address RECIPEINT_THREE = makeAddr("RECIPEINT_THREE");

    address[] NO_MEMBERS;

    // GROUP ONE - 3/5 required
    string GROUP_ONE_NAME = "Boston Celtics";
    uint256 GROUP_ONE_START_AMOUNT = 20e18;
    address[] GROUP_ONE_MEMBERS = [USER_ONE, USER_TWO, USER_THREE, USER_FOUR];
    address[] GROUP_ONE_MEMBERS_WITH_CREATOR = [USER_ONE, USER_TWO, USER_THREE, USER_FOUR, CREATOR_ONE];
    address[] GROUP_ONE_MEMBERS_WITH_ZERO_ADRDESS = [USER_ONE, USER_TWO, USER_THREE, address(0), CREATOR_ONE];
    uint256 GROUP_ONE_QUORUM = 3;

    // GROUP TWO - 2/2 required
    string GROUP_TWO_NAME = "Dallas Mavericks";
    uint256 GROUP_TWO_START_AMOUNT = 25e18;
    address[] GROUP_TWO_MEMBERS = [USER_FIVE];
    address[] GROUP_TWO_MEMBERS_WITH_CREATOR = [USER_FIVE, CREATOR_TWO];
    uint256 GROUP_TWO_QUORUM = 2;

    // Group 1 Proposal 1
    string PROPOSAL_REASON_ONE = "Ken Family Registers";
    address[] PROPOSAL_ONE_RECIPIENTS = [RECIPEINT_ONE, RECIPEINT_TWO];
    address[] PROPOSAL_ONE_RECIPIENTS_WITH_ADDRESS_ZERO = [RECIPEINT_ONE, address(0)];
    uint256[] PROPOSAL_ONE_AMOUNT = [10e18, 2e18];
    uint256[] PROPOSAL_ONE_AMOUNT_WITH_ZERO = [0, 2e18];

    // Group Two Proposal 1
    string PROPOSAL_REASON_TWO = "Pigs Dine In Easter";
    uint256[] PROPOSAL_TWO_AMOUNT = [17e18];
    address[] PROPOSAL_TWO_RECIPIENTS = [RECIPEINT_THREE];

    GroupSave groupSave;
    MockMTRG MTRG;

    function setUp() public {
        DeployGroupSave deployGroupSave = new DeployGroupSave();
        (groupSave, mtrgAddress) = deployGroupSave.run();
        MTRG = MockMTRG(mtrgAddress);
    }

    function _approveMTRG(address _user, uint256 _amount) internal {
        vm.startPrank(_user);
        MTRG.mintToUser(_user, _amount);
        MTRG.approve(address(groupSave), _amount);
        vm.stopPrank();
    }

    function _createGroupSaveOne() internal {
        _approveMTRG(CREATOR_ONE, GROUP_ONE_START_AMOUNT);

        vm.startPrank(CREATOR_ONE);
        groupSave.createGroupSave({
            _groupSaveName: GROUP_ONE_NAME,
            _startingAmount: GROUP_ONE_START_AMOUNT,
            _members: GROUP_ONE_MEMBERS,
            _quorum: GROUP_ONE_QUORUM
        });
        vm.stopPrank();
    }

    function _createGroupSaveTwo() internal {
        _approveMTRG(CREATOR_TWO, GROUP_TWO_START_AMOUNT);

        vm.startPrank(CREATOR_TWO);
        groupSave.createGroupSave({
            _groupSaveName: GROUP_TWO_NAME,
            _startingAmount: GROUP_TWO_START_AMOUNT,
            _members: GROUP_TWO_MEMBERS,
            _quorum: GROUP_TWO_QUORUM
        });
        vm.stopPrank();
    }

    function _createGroupSaveOneProposalOne() internal {
        uint256 groupIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        groupSave.createGroupSaveProposal({
            _groupId: groupIdOne,
            _reason: PROPOSAL_REASON_ONE,
            _amounts: PROPOSAL_ONE_AMOUNT,
            _recipients: PROPOSAL_ONE_RECIPIENTS
        });
        vm.stopPrank();
    }

    function _createGroupSaveTwoProposalOne() internal {
        uint256 groupIdTwo = 2;

        vm.startPrank(CREATOR_TWO);
        groupSave.createGroupSaveProposal({
            _groupId: groupIdTwo,
            _reason: PROPOSAL_REASON_TWO,
            _amounts: PROPOSAL_TWO_AMOUNT,
            _recipients: PROPOSAL_TWO_RECIPIENTS
        });
        vm.stopPrank();
    }

    function _acceptCompleteGroupOneProposalOne() internal {
        uint256 groupIdOne = 1;
        uint256 proposalIdOne = 1;

        vm.prank(USER_ONE);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: true});
        vm.prank(USER_TWO);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: true});
        vm.prank(USER_THREE);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: true});
    }

    function _acceptCompleteGroupTwoProposalOne() internal {
        uint256 groupIdTwo = 2;
        uint256 proposalIdTwo = 1;

        vm.prank(CREATOR_TWO);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdTwo, _proposalId: proposalIdTwo, _decision: true});
        vm.prank(USER_FIVE);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdTwo, _proposalId: proposalIdTwo, _decision: true});
    }

    function _rejectCompleteGroupOneProposalOne() internal {
        uint256 groupIdOne = 1;
        uint256 proposalIdOne = 1;

        vm.prank(USER_ONE);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: false});
        vm.prank(USER_TWO);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: false});
        vm.prank(USER_THREE);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: true});
        vm.prank(USER_FOUR);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: false});
    }

    function _sumAmount(uint256[] memory _amounts) internal pure returns (uint256) {
        uint256 totalAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        return totalAmount;
    }
}
