// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

// Oz's Imports
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SaveSphere: Group Save Contract
 * @author E.Francis
 * @notice Group Save allows multiple users to come together, save and manage funds and activities that surround the usage of the group funds as
 * a group, they can be used by family, friends, organizations etc.
 */
contract GroupSave is ReentrancyGuard {
    // Errors
    error GroupSave__MsgSenderShouldNotBeInMembersList();
    error GroupSave__MinimumOfTwoMembersRequired();
    error GroupSave__QuorumCantBeGreaterThanMembers();
    error GroupSave_StartingAmountCannotBeZero();
    error GroupSave__GroupMemberCannotBeZeroAddress();
    error GroupSave__GroupDoesNotExist();
    error GroupSave__NonMemberCannotCreateProposal();
    error GroupSave__RecipientCannotBeZeroAddress();
    error GroupSave__NoIndividualAmountCanBeZero();
    error GroupSave__ProposalAmountGreaterThanPendingGroupBalance();
    error GroupSave__RecipientsAndAmountsDoNotMatch();
    error GroupSave__ProposalDoesNotExist();
    error GroupSave__NonMemberCannotAcceptOrRejectProposal();
    error GroupSave__ProposalAlreadyCompleted();
    error GroupSave__MemberAlreadyParticipated();
    error GroupSave__QurumMustBeGreaterThanOne();
    error GroupSave__TopUpAmountCannotBeZero();

    // Events
    event GroupSaveCreated(
        uint256 groupId,
        string groupName,
        address[] members,
        uint256 quorum,
        uint256 amount,
        uint256 proposalCount,
        uint256 pendingAmount
    );

    event ProposalCreated(
        uint256 groupId,
        uint256 proposalId,
        string reason,
        uint256 accepted,
        uint256 rejected,
        uint256[] amounts,
        address[] recipients,
        uint8 completed,
        uint256 groupPendingAmount
    );

    event GroupMemberPartipated(uint256 groupId, uint256 proposalId, bool decision);

    event GroupProposalCompleted(uint256 groupId, uint256 proposalId, uint256 proposalAmount, uint8 completed);

    event GroupSaveTopUp(uint256 groupId, uint256 amount);

    // Types

    struct GroupSavings {
        uint256 groupId;
        string name;
        address[] members;
        uint256 quorum;
        uint256 amount;
        uint256 proposalCount;
        uint256 pendingAmount;
    }

    struct Proposal {
        uint256 proposalId;
        string reason;
        uint256 accepted;
        uint256 rejected;
        uint256[] amounts;
        address[] recipients;
        uint256 completed;
    }

    IERC20 MTRG;

    // Storage
    uint256 groupIdCounter;

    GroupSavings[] groupSavings;
    mapping(uint256 groupId => Proposal[]) _proposals;

    mapping(uint256 groupId => mapping(uint256 proposalId => mapping(address user => bool participated))) _participated;

    mapping(uint256 groupId => uint256 propsalCounter) _proposalCounter;

    // Modifiers
    modifier groupMustExist(uint256 _groupId) {
        if (_groupId > groupIdCounter) {
            revert GroupSave__GroupDoesNotExist();
        }
        _;
    }

    /**
     * @param _mtrg the address of the MTRG token
     */
    constructor(address _mtrg) {
        MTRG = IERC20(_mtrg);
    }

    /**
     * Creates a group saving with specified amount of members with equal power
     * The additional "+1" in the checks are to account for the inclusion of the msg.sender in the final members array
     * @param _groupSaveName the name of the group savings
     * @param _startingAmount the starting amount of the group savings
     * @param _members the members list of the group save excluding the msg.sender
     * @param _quorum the minimum amount of members required to pass a proposal
     */
    function createGroupSave(
        string memory _groupSaveName,
        uint256 _startingAmount,
        address[] memory _members,
        uint256 _quorum
    ) external nonReentrant {
        _createGroupSaveChecks(_members, _quorum, _startingAmount);

        address[] memory completeMembers = _addCreatorToMembers(_members);

        SafeERC20.safeTransferFrom(MTRG, msg.sender, address(this), _startingAmount);

        groupIdCounter++;
        groupSavings.push(
            GroupSavings({
                groupId: groupIdCounter,
                name: _groupSaveName,
                members: completeMembers,
                quorum: _quorum,
                amount: _startingAmount,
                proposalCount: 0,
                pendingAmount: 0
            })
        );

        emit GroupSaveCreated(groupIdCounter, _groupSaveName, completeMembers, _quorum, _startingAmount, 0, 0);
    }

    /**
     * Creates a group save proposal to distribute funds from the group to a set of recipients from the group balance
     * @param _groupId the group save Id that the proposal would be sent from
     * @param _reason the reason for the proposal
     * @param _amounts the list of amounts to be sent to the individual users in the proposal
     * @param _recipients the list of recipients to receive the funds stored in the proposal
     */
    function createGroupSaveProposal(
        uint256 _groupId,
        string memory _reason,
        uint256[] memory _amounts,
        address[] memory _recipients
    ) external nonReentrant groupMustExist(_groupId) {
        uint256 totalAmount = _createGroupProposalChecks(_groupId, _recipients, _amounts);
        uint256 proposalId = groupSavings[_groupId - 1].proposalCount += 1;

        groupSavings[_groupId - 1].pendingAmount += totalAmount;

        _proposals[_groupId].push(
            Proposal({
                proposalId: proposalId,
                reason: _reason,
                accepted: 0,
                rejected: 0,
                amounts: _amounts,
                recipients: _recipients,
                completed: 0
            })
        );

        emit ProposalCreated(_groupId, proposalId, _reason, 0, 0, _amounts, _recipients, 0, 0);
    }

    /**
     * Allows a group member accept or reject open proposals in their group savings
     * @param _groupId the group save Id
     * @param _proposalId the gorup save proposal Id
     * @param _decision the decision made by the member, false = against, true = for
     */
    function acceptOrRejectGroupSaveProposal(uint256 _groupId, uint256 _proposalId, bool _decision)
        external
        nonReentrant
        groupMustExist(_groupId)
    {
        _acceptOrRejectProposalChecks(_groupId, _proposalId);

        if (_decision) {
            _proposals[_groupId][_proposalId - 1].accepted += 1;
        } else {
            _proposals[_groupId][_proposalId - 1].rejected += 1;
        }

        _participated[_groupId][_proposalId][msg.sender] = true;

        emit GroupMemberPartipated(_groupId, _proposalId, _decision);

        _handleUserProposalDecisionOutcome(_groupId, _proposalId);
    }

    /**
     * Allows any user to top up the savings in a group save
     * @param _groupId the id of the group save
     * @param _amount the amount to top up the group save balance with
     */
    function topUpGroupSave(uint256 _groupId, uint256 _amount) public nonReentrant {
        if (_amount == 0) {
            revert GroupSave__TopUpAmountCannotBeZero();
        }

        SafeERC20.safeTransferFrom(MTRG, msg.sender, address(this), _amount);
        groupSavings[_groupId - 1].amount += _amount;

        emit GroupSaveTopUp(_groupId, _amount);
    }

    // INTERNAL FUNCTIONS

    /**
     * Adds the msg.sender to the members
     * @param _members the list of members of a group without the msg.sender
     */
    function _addCreatorToMembers(address[] memory _members) internal view returns (address[] memory) {
        address[] memory completeMembers = new address[](_members.length + 1);
        for (uint256 i = 0; i < _members.length; i++) {
            completeMembers[i] = _members[i];
        }
        completeMembers[_members.length] = msg.sender;

        return completeMembers;
    }

    /**
     * Checks that all the params sent are okay to create a group save and reverts if any condition is not satisfied, checks include
     * - msg sender shoudl not be part of initial members list sent
     * - no group member can be the zero address
     * - the group save must have at least two members i.e including the msg.sender
     * - the quorum required for the group proposal pass cannot be greater than the total group members
     * - the starting balance when creating a group cannot be zero
     * - The quorum must be greater than 1
     * @param _members the members of the group save excluding the msg.sender
     * @param _quorum the amount ofmembers required for the group proposal to pass
     * @param _startingAmount the starting amount funded into the group balance on creation
     */
    function _createGroupSaveChecks(address[] memory _members, uint256 _quorum, uint256 _startingAmount)
        internal
        view
    {
        for (uint256 i = 0; i < _members.length; i++) {
            if (_members[i] == msg.sender) {
                revert GroupSave__MsgSenderShouldNotBeInMembersList();
            }
            if (_members[i] == address(0)) {
                revert GroupSave__GroupMemberCannotBeZeroAddress();
            }
        }
        if (_members.length == 0) {
            revert GroupSave__MinimumOfTwoMembersRequired();
        }
        if (_quorum > _members.length + 1) {
            revert GroupSave__QuorumCantBeGreaterThanMembers();
        }
        if (_startingAmount == 0) {
            revert GroupSave_StartingAmountCannotBeZero();
        }
        if (_quorum <= 1) {
            revert GroupSave__QurumMustBeGreaterThanOne();
        }
    }

    /**
     * Checks that all the params sent are okay to create a group proposal and reverts if any condition is not satisfied, checks include
     * - the msg.sender of the proposal must be a member of the group
     * - none of the recipients can be the zero address
     * - no individual amount to be sent can be equal to zero
     * - the recipients and amounts list length must be equal
     * - the proposal total amount + already pending group amount has to be less than the group total balance
     * @param _groupId the group save Id
     * @param _recipients the group proposal recipients
     * @param _amounts the individual group proposal amounts to be sent
     */
    function _createGroupProposalChecks(uint256 _groupId, address[] memory _recipients, uint256[] memory _amounts)
        internal
        view
        returns (uint256)
    {
        address[] memory groupMembers = groupSavings[_groupId - 1].members;
        bool isMember = false;
        for (uint256 i = 0; i < groupMembers.length; i++) {
            if (msg.sender == groupMembers[i]) {
                isMember = true;
            }
        }
        if (!isMember) {
            revert GroupSave__NonMemberCannotCreateProposal();
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] == address(0)) {
                revert GroupSave__RecipientCannotBeZeroAddress();
            }
        }

        uint256 totalAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
            if (_amounts[i] == 0) {
                revert GroupSave__NoIndividualAmountCanBeZero();
            }
        }

        if (_recipients.length != _amounts.length) {
            revert GroupSave__RecipientsAndAmountsDoNotMatch();
        }

        if (totalAmount + groupSavings[_groupId - 1].pendingAmount > groupSavings[_groupId - 1].amount) {
            revert GroupSave__ProposalAmountGreaterThanPendingGroupBalance();
        }

        return totalAmount;
    }

    /**
     * Checks that all the params sent are okay to create a group proposal and reverts if any condition is not satisfied, checks include
     * - the group proposal must exist
     * - the msg.sender must be a member of the group
     * - the proposal must not be completed already
     * - the msg.sender must have not already accepted or rejected
     * @param _groupId the group save Id
     * @param _proposalId the group proposal Id
     */
    function _acceptOrRejectProposalChecks(uint256 _groupId, uint256 _proposalId) internal view {
        if (_proposalId > groupSavings[_groupId - 1].proposalCount) {
            revert GroupSave__ProposalDoesNotExist();
        }

        address[] memory groupMembers = groupSavings[_groupId - 1].members;
        bool isMember = false;
        for (uint256 i = 0; i < groupMembers.length; i++) {
            if (msg.sender == groupMembers[i]) {
                isMember = true;
            }
        }
        if (!isMember) {
            revert GroupSave__NonMemberCannotAcceptOrRejectProposal();
        }

        if (_proposals[_groupId][_proposalId - 1].completed != 0) {
            revert GroupSave__ProposalAlreadyCompleted();
        }

        if (_participated[_groupId][_proposalId][msg.sender]) {
            revert GroupSave__MemberAlreadyParticipated();
        }
    }

    /**
     * Handles the groups members decision if an outcome has been met i.e
     * - if the proposal was succesful
     * - or if the proposal is mathematically impossible to be succesfull
     * @param _groupId the group save Id
     * @param _proposalId the group save proposal Id
     */
    function _handleUserProposalDecisionOutcome(uint256 _groupId, uint256 _proposalId) internal {
        uint256 membersLength = groupSavings[_groupId - 1].members.length;
        uint256 groupQuorum = groupSavings[_groupId - 1].quorum;
        (address[] memory recipients, uint256[] memory amounts) = getRecipientsAndAmountsList(_groupId, _proposalId);

        uint256 forProposal = _proposals[_groupId][_proposalId - 1].accepted;
        uint256 againstProposal = _proposals[_groupId][_proposalId - 1].rejected;

        if (forProposal >= groupQuorum) {
            uint256 totalAmount;
            for (uint256 i = 0; i < recipients.length; i++) {
                totalAmount += amounts[i];
                SafeERC20.safeTransfer(MTRG, recipients[i], amounts[i]);
            }

            _proposals[_groupId][_proposalId - 1].completed = 1;
            groupSavings[_groupId - 1].amount -= totalAmount;
            groupSavings[_groupId - 1].pendingAmount -= totalAmount;

            emit GroupProposalCompleted(_groupId, _proposalId, totalAmount, 1);
        }

        if (membersLength - againstProposal < groupQuorum) {
            uint256 totalAmount;
            for (uint256 i = 0; i < amounts.length; i++) {
                totalAmount += amounts[i];
            }
            _proposals[_groupId][_proposalId - 1].completed = 2;
            groupSavings[_groupId - 1].pendingAmount -= totalAmount;

            emit GroupProposalCompleted(_groupId, _proposalId, totalAmount, 2);
        }
    }

    // GETTER FUNCIONS

    /**
     * Gets the recipients and the amount to be sent to each of them into two different arrays of equal length
     * @param _groupId the group save Id
     * @param _proposalId the group save proposal Id
     * @return the list of recipients
     * @return the list of amounts
     */
    function getRecipientsAndAmountsList(uint256 _groupId, uint256 _proposalId)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 recipientsLength = _proposals[_groupId][_proposalId - 1].recipients.length;

        address[] memory recipients = new address[](recipientsLength);
        uint256[] memory amounts = new uint256[](recipientsLength);

        for (uint256 i = 0; i < recipientsLength; i++) {
            recipients[i] = _proposals[_groupId][_proposalId - 1].recipients[i];
            amounts[i] = _proposals[_groupId][_proposalId - 1].amounts[i];
        }

        return (recipients, amounts);
    }

    /**
     * Gets the group savings details from its id
     * @param _groupId the of of the group savings
     */
    function getGroupSavings(uint256 _groupId) public view returns (GroupSavings memory) {
        return groupSavings[_groupId - 1];
    }

    /**
     * Gets all the group savings details
     */
    function getAllGroupSavings() public view returns (GroupSavings[] memory) {
        return groupSavings;
    }

    /**
     * Get the group save proposal by its Id and the group Id
     * @param _groupId the group Id
     * @param _proposalId the proposal Id for the group
     */
    function getGroupProposal(uint256 _groupId, uint256 _proposalId) public view returns (Proposal memory) {
        return _proposals[_groupId][_proposalId - 1];
    }

    /**
     * Get the group save proposal from a particular group
     * @param _groupId the group Id
     */
    function getAllProposalsForGroup(uint256 _groupId) public view returns (Proposal[] memory) {
        return _proposals[_groupId];
    }

    /**
     * Gets whether a certain member in a group has participated in a particular group proposal
     * @param _user the address of the group member
     * @param _groupId the Id of the group
     * @param _proposalId the Id of the proposal
     */
    function getUserProposalParticipation(address _user, uint256 _groupId, uint256 _proposalId)
        public
        view
        returns (bool)
    {
        return _participated[_groupId][_proposalId][_user];
    }

    /**
     * gets the current time stamp
     */
    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}
