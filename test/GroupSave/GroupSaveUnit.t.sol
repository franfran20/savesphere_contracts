// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {console} from "forge-std/Test.sol";
import {GroupSave} from "../../src/SaveSphere/GroupSave.sol";
import {GroupSaveBaseTest} from "./GroupSaveBase.t.sol";

contract FlexSaveUnitTest is GroupSaveBaseTest {
    ////////////////////////////////////////////////
    ////////////// CREATE GROUP SAVE //////////////
    ////////////////////////////////////////////////

    function testCreateGroupSave__TransfersStartAmountSuccesfully() public {
        _approveMTRG(CREATOR_ONE, GROUP_ONE_START_AMOUNT);

        vm.startPrank(CREATOR_ONE);
        groupSave.createGroupSave({
            _groupSaveName: GROUP_ONE_NAME,
            _startingAmount: GROUP_ONE_START_AMOUNT,
            _members: GROUP_ONE_MEMBERS,
            _quorum: GROUP_ONE_QUORUM
        });
        vm.stopPrank();

        assertEq(MTRG.balanceOf(address(groupSave)), GROUP_ONE_START_AMOUNT);
    }

    function testCreateGroupSave__UpdatesTheGroupSaveDetails() public {
        _createGroupSaveOne();
        _createGroupSaveTwo();

        uint256 groupIdTwo = 2;

        GroupSave.GroupSavings memory groupSavingsTwo = groupSave.getGroupSavings(groupIdTwo);

        assertEq(groupSavingsTwo.groupId, groupIdTwo);
        assertEq(groupSavingsTwo.name, GROUP_TWO_NAME);
        assertEq(groupSavingsTwo.members, GROUP_TWO_MEMBERS_WITH_CREATOR);
        assertEq(groupSavingsTwo.quorum, GROUP_TWO_QUORUM);
        assertEq(groupSavingsTwo.amount, GROUP_TWO_START_AMOUNT);
        assertEq(groupSavingsTwo.proposalCount, 0);
        assertEq(groupSavingsTwo.pendingAmount, 0);
    }

    function testCreateGroupSave__Reverts__IfTheMsgSenderIsInMembersList() public {
        _approveMTRG(CREATOR_ONE, GROUP_ONE_START_AMOUNT);

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__MsgSenderShouldNotBeInMembersList.selector);
        groupSave.createGroupSave({
            _groupSaveName: GROUP_ONE_NAME,
            _startingAmount: GROUP_ONE_START_AMOUNT,
            _members: GROUP_ONE_MEMBERS_WITH_CREATOR,
            _quorum: GROUP_ONE_QUORUM
        });
        vm.stopPrank();
    }

    function testCreateGroupSave__Reverts__IfAnyMemberIsTheZeroAddress() public {
        _approveMTRG(CREATOR_ONE, GROUP_ONE_START_AMOUNT);

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__GroupMemberCannotBeZeroAddress.selector);
        groupSave.createGroupSave({
            _groupSaveName: GROUP_ONE_NAME,
            _startingAmount: GROUP_ONE_START_AMOUNT,
            _members: GROUP_ONE_MEMBERS_WITH_ZERO_ADRDESS,
            _quorum: GROUP_ONE_QUORUM
        });
        vm.stopPrank();
    }

    function testCretreGroupSave__Reverts__IfTheMembersListIsEmpty() public {
        _approveMTRG(CREATOR_ONE, GROUP_ONE_START_AMOUNT);

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__MinimumOfTwoMembersRequired.selector);
        groupSave.createGroupSave({
            _groupSaveName: GROUP_ONE_NAME,
            _startingAmount: GROUP_ONE_START_AMOUNT,
            _members: NO_MEMBERS,
            _quorum: GROUP_ONE_QUORUM
        });
        vm.stopPrank();
    }

    function testCreateGroupSave__Reverts__IfQuorumIsGreaterThanMembersIncludingCreator() public {
        _approveMTRG(CREATOR_ONE, GROUP_ONE_START_AMOUNT);

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__QuorumCantBeGreaterThanMembers.selector);
        groupSave.createGroupSave({
            _groupSaveName: GROUP_ONE_NAME,
            _startingAmount: GROUP_ONE_START_AMOUNT,
            _members: GROUP_ONE_MEMBERS,
            _quorum: GROUP_ONE_QUORUM + 3
        });
        vm.stopPrank();
    }

    function testCreateGroupSave__Reverts__IfSavingStartingAmountIsZero() public {
        _approveMTRG(CREATOR_ONE, GROUP_ONE_START_AMOUNT);

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave_StartingAmountCannotBeZero.selector);
        groupSave.createGroupSave({
            _groupSaveName: GROUP_ONE_NAME,
            _startingAmount: 0,
            _members: GROUP_ONE_MEMBERS,
            _quorum: GROUP_ONE_QUORUM
        });
        vm.stopPrank();
    }

    function testCreateGroupSave__Reverts__IfQuorumIsOnlyASingleMember() public {
        _approveMTRG(CREATOR_TWO, GROUP_TWO_START_AMOUNT);

        vm.startPrank(CREATOR_TWO);
        vm.expectRevert(GroupSave.GroupSave__QurumMustBeGreaterThanOne.selector);
        groupSave.createGroupSave({
            _groupSaveName: GROUP_TWO_NAME,
            _startingAmount: GROUP_TWO_START_AMOUNT,
            _members: GROUP_TWO_MEMBERS,
            _quorum: 1
        });
        vm.stopPrank();
    }

    //////////////////////////////////////////////////
    ////////////// CREATE GROUP PROPOSAL //////////////
    //////////////////////////////////////////////////

    function testCreateProposal__UpdatesTheGroupSavingsDetails() public {
        _createGroupSaveOne();
        uint256 groupIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        groupSave.createGroupSaveProposal({
            _groupId: groupIdOne,
            _reason: PROPOSAL_REASON_ONE,
            _amounts: PROPOSAL_ONE_AMOUNT,
            _recipients: PROPOSAL_ONE_RECIPIENTS
        });
        vm.stopPrank();

        GroupSave.GroupSavings memory groupSavingsOne = groupSave.getGroupSavings(groupIdOne);

        assertEq(groupSavingsOne.proposalCount, 1);
        assertEq(groupSavingsOne.pendingAmount, _sumAmount(PROPOSAL_ONE_AMOUNT));
    }

    function testCreateProposal__UpdatesTheGroupProposalDetails() public {
        _createGroupSaveOne();
        uint256 groupIdOne = 1;
        uint256 proposalIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        groupSave.createGroupSaveProposal({
            _groupId: groupIdOne,
            _reason: PROPOSAL_REASON_ONE,
            _amounts: PROPOSAL_ONE_AMOUNT,
            _recipients: PROPOSAL_ONE_RECIPIENTS
        });
        vm.stopPrank();

        GroupSave.Proposal memory groupSaveOneProposalOne = groupSave.getGroupProposal(groupIdOne, proposalIdOne);

        assertEq(groupSaveOneProposalOne.proposalId, proposalIdOne);
        assertEq(groupSaveOneProposalOne.reason, PROPOSAL_REASON_ONE);
        assertEq(groupSaveOneProposalOne.accepted, 0);
        assertEq(groupSaveOneProposalOne.rejected, 0);
        assertEq(groupSaveOneProposalOne.amounts, PROPOSAL_ONE_AMOUNT);
        assertEq(groupSaveOneProposalOne.recipients, PROPOSAL_ONE_RECIPIENTS);
        assertEq(groupSaveOneProposalOne.completed, 0);
    }

    function testCreateProposal__Reverts__IfGroupDoesNotExist() public {
        _createGroupSaveOne();
        uint256 nonExistentGroupId = 10;

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__GroupDoesNotExist.selector);
        groupSave.createGroupSaveProposal({
            _groupId: nonExistentGroupId,
            _reason: PROPOSAL_REASON_ONE,
            _amounts: PROPOSAL_ONE_AMOUNT,
            _recipients: PROPOSAL_ONE_RECIPIENTS
        });
        vm.stopPrank();
    }

    function testCreateProposal__Reverts__IfUserIsNotAMemberOfTheGroup() public {
        _createGroupSaveOne();
        uint256 groupIdOne = 1;

        vm.startPrank(CREATOR_TWO);
        vm.expectRevert(GroupSave.GroupSave__NonMemberCannotCreateProposal.selector);
        groupSave.createGroupSaveProposal({
            _groupId: groupIdOne,
            _reason: PROPOSAL_REASON_ONE,
            _amounts: PROPOSAL_ONE_AMOUNT,
            _recipients: PROPOSAL_ONE_RECIPIENTS
        });
        vm.stopPrank();
    }

    function testCreateProposal__Reverts__IfAnyRecipientIsAddressZero() public {
        _createGroupSaveOne();
        uint256 groupIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__RecipientCannotBeZeroAddress.selector);
        groupSave.createGroupSaveProposal({
            _groupId: groupIdOne,
            _reason: PROPOSAL_REASON_ONE,
            _amounts: PROPOSAL_ONE_AMOUNT,
            _recipients: PROPOSAL_ONE_RECIPIENTS_WITH_ADDRESS_ZERO
        });
        vm.stopPrank();
    }

    function testCreateProposal__Reverts__IfAnyRecipientAmountIsZero() public {
        _createGroupSaveOne();
        uint256 groupIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__NoIndividualAmountCanBeZero.selector);
        groupSave.createGroupSaveProposal({
            _groupId: groupIdOne,
            _reason: PROPOSAL_REASON_ONE,
            _amounts: PROPOSAL_ONE_AMOUNT_WITH_ZERO,
            _recipients: PROPOSAL_ONE_RECIPIENTS
        });
        vm.stopPrank();
    }

    function testCreateProposal__Reverts__IfRecipientsAndAmountsListLengthDoNotMatch() public {
        _createGroupSaveOne();
        uint256 groupIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__RecipientsAndAmountsDoNotMatch.selector);
        groupSave.createGroupSaveProposal({
            _groupId: groupIdOne,
            _reason: PROPOSAL_REASON_ONE,
            _amounts: PROPOSAL_TWO_AMOUNT,
            _recipients: PROPOSAL_ONE_RECIPIENTS
        });
        vm.stopPrank();
    }

    function testCreateProposal__Reverts__IfProposalAmountBalanceIsGreaterThanPendingBalance() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();

        uint256 groupIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__ProposalAmountGreaterThanPendingGroupBalance.selector);
        groupSave.createGroupSaveProposal({
            _groupId: groupIdOne,
            _reason: PROPOSAL_REASON_ONE,
            _amounts: PROPOSAL_ONE_AMOUNT,
            _recipients: PROPOSAL_ONE_RECIPIENTS
        });
        vm.stopPrank();
    }

    //////////////////////////////////////////////
    //////// ACCEPT / REJECT PROPOSAL //////////
    /////////////////////////////////////////////

    function testAcceptOrRejectProposal__IncreasesAccpeptedCountIfDecisionIsTrue() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();

        uint256 groupIdOne = 1;
        uint256 proposalIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: true});
        vm.stopPrank();

        GroupSave.Proposal memory groupSaveOneProposalOne = groupSave.getGroupProposal(groupIdOne, proposalIdOne);

        assertEq(groupSaveOneProposalOne.accepted, 1);
    }

    function testAcceptOrRejectProposal__IncreasesRejectedCountIfDecisionIsFalse() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();

        uint256 groupIdOne = 1;
        uint256 proposalIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: false});
        vm.stopPrank();

        GroupSave.Proposal memory groupSaveOneProposalOne = groupSave.getGroupProposal(groupIdOne, proposalIdOne);

        assertEq(groupSaveOneProposalOne.rejected, 1);
    }

    function testAcceptOrRejectProposal__UpdatesTheMemebersParticipatedStatus() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();

        uint256 groupIdOne = 1;
        uint256 proposalIdOne = 1;

        vm.startPrank(CREATOR_ONE);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalIdOne, _decision: false});
        vm.stopPrank();

        bool creatorOneParticipated = groupSave.getUserProposalParticipation(CREATOR_ONE, groupIdOne, proposalIdOne);

        assertEq(creatorOneParticipated, true);
    }

    function testAcceptOrRejectProposal__UpdatesProposalAndGroupDetails__OnProposalAcceptance() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();
        _acceptCompleteGroupOneProposalOne();

        uint256 groupIdOne = 1;
        uint256 proposalIdOne = 1;

        GroupSave.Proposal memory groupSaveOneProposalOne = groupSave.getGroupProposal(groupIdOne, proposalIdOne);
        GroupSave.GroupSavings memory groupSavingsOne = groupSave.getGroupSavings(groupIdOne);

        assertEq(groupSaveOneProposalOne.completed, 1);

        assertEq(groupSavingsOne.amount, GROUP_ONE_START_AMOUNT - _sumAmount(PROPOSAL_ONE_AMOUNT));
        assertEq(groupSavingsOne.pendingAmount, 0);
    }

    function testAcceptOrRejectProposal__TranfersFundsToRecipients__OnProposalAcceptance() public {
        _createGroupSaveOne();
        _createGroupSaveTwo();
        _createGroupSaveTwoProposalOne();

        uint256 recipientOneBalanceBeforeAcceptance = MTRG.balanceOf(RECIPEINT_THREE);
        _acceptCompleteGroupTwoProposalOne();

        assertEq(MTRG.balanceOf(RECIPEINT_THREE), recipientOneBalanceBeforeAcceptance + PROPOSAL_TWO_AMOUNT[0]);
    }

    function testAcceptOrRejectProposal__UpdatesProposalAndGroupDetails__OnProposalRejection() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();
        _rejectCompleteGroupOneProposalOne();

        uint256 groupIdOne = 1;
        uint256 proposalIdOne = 1;

        GroupSave.Proposal memory groupSaveOneProposalOne = groupSave.getGroupProposal(groupIdOne, proposalIdOne);
        GroupSave.GroupSavings memory groupSavingsOne = groupSave.getGroupSavings(groupIdOne);

        assertEq(groupSaveOneProposalOne.completed, 2);
        assertEq(groupSavingsOne.pendingAmount, 0);
    }

    function testAcceptOrRejectProposal__Reverts__IfTheProposalDoesNotExist() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();

        uint256 groupIdOne = 1;
        uint256 nonExistentProposal = 10;

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__ProposalDoesNotExist.selector);
        groupSave.acceptOrRejectGroupSaveProposal({
            _groupId: groupIdOne,
            _proposalId: nonExistentProposal,
            _decision: true
        });
        vm.stopPrank();
    }

    function testAcceptOrRejectProposal__Reverts__IfTheUserIsNotAGroupMember() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();

        uint256 groupIdOne = 1;
        uint256 proposalId = 1;

        vm.startPrank(CREATOR_TWO);
        vm.expectRevert(GroupSave.GroupSave__NonMemberCannotAcceptOrRejectProposal.selector);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalId, _decision: true});
        vm.stopPrank();
    }

    function testAcceptOrRejectProposal__Reverts__IfProposalIsAlreadyCompleted() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();
        _acceptCompleteGroupOneProposalOne();

        uint256 groupIdOne = 1;
        uint256 proposalId = 1;

        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__ProposalAlreadyCompleted.selector);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalId, _decision: false});
        vm.stopPrank();
    }

    function testAcceptOrRejectProposal__Reverts__IfGroupMemberAlreadyParticipated() public {
        _createGroupSaveOne();
        _createGroupSaveOneProposalOne();

        uint256 groupIdOne = 1;
        uint256 proposalId = 1;

        vm.startPrank(CREATOR_ONE);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalId, _decision: false});

        vm.expectRevert(GroupSave.GroupSave__MemberAlreadyParticipated.selector);
        groupSave.acceptOrRejectGroupSaveProposal({_groupId: groupIdOne, _proposalId: proposalId, _decision: true});
        vm.stopPrank();
    }

    ////////////////////////////////////
    ///////// TOP UP GROUP SAVE ////////
    ///////////////////////////////////

    function testTopUpGroupSave__TransferMTRGFromTheUserToTheGroupSave() public {
        _createGroupSaveOne();

        uint256 groupIdOne = 1;

        _approveMTRG(CREATOR_ONE, GROUP_TOP_UP_AMOUNT);
        vm.startPrank(CREATOR_ONE);
        groupSave.topUpGroupSave({_groupId: groupIdOne, _amount: GROUP_TOP_UP_AMOUNT});
        vm.stopPrank();

        assertEq(MTRG.balanceOf(address(groupSave)), GROUP_ONE_START_AMOUNT + GROUP_TOP_UP_AMOUNT);
    }

    function testTopUpGroupSave__UpdatesTheGroupSaveBalance() public {
        _createGroupSaveOne();

        uint256 groupIdOne = 1;

        _approveMTRG(CREATOR_ONE, GROUP_TOP_UP_AMOUNT);
        vm.startPrank(CREATOR_ONE);
        groupSave.topUpGroupSave({_groupId: groupIdOne, _amount: GROUP_TOP_UP_AMOUNT});
        vm.stopPrank();

        GroupSave.GroupSavings memory groupSavingsOne = groupSave.getGroupSavings(groupIdOne);

        assertEq(groupSavingsOne.amount, GROUP_ONE_START_AMOUNT + GROUP_TOP_UP_AMOUNT);
    }

    function testTopUpGroupSave__Reverts__IfTopUpAmountIsZero() public {
        _createGroupSaveOne();

        uint256 groupIdOne = 1;

        _approveMTRG(CREATOR_ONE, GROUP_TOP_UP_AMOUNT);
        vm.startPrank(CREATOR_ONE);
        vm.expectRevert(GroupSave.GroupSave__TopUpAmountCannotBeZero.selector);
        groupSave.topUpGroupSave({_groupId: groupIdOne, _amount: 0});
        vm.stopPrank();
    }
}
