// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

// Oz's Imports
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SaveSphere: Target Driven Save
 * @author E.Francis
 * @notice Target Driven Save Contract Allows For Users To Save To Reach Their Savings Target With Conditons Such as Time Based Savings,
 * Target Amount Based Savings Or Both!
 */
contract TargetDrivenSave is ReentrancyGuard {
    // ERRORS
    error TargetDrivenSave__SaveDoesNotExist();
    error TargetDrivenSave__AmountTargetConditionNotSatisfied();
    error TargetDrivenSave__TimeConditionNotSatisfied();
    error TargetDrivenSave__AtLeastOneConditionMustBeSet();
    error TargetDrivenSave__SaveAlreadyUnlocked();
    error TargetDrivenSave__AmountCannnotBeZero();
    error TargetDrivenSave__TopUpMustIncludeTimeOrAmount();
    error TargetDrivenSave__TargetAmountMustBeGreaterThanStartAmount();

    // EVENTS

    event TargetDrivenSaveCreated(
        address user,
        uint256 saveId,
        string reason,
        uint256 amount,
        uint256 targetAmount,
        uint256 startTime,
        uint256 stopTime,
        bool completed
    );
    event TargetDrivenSaveToppedUp(address user, uint256 saveId, uint256 topUpAmount);
    event TargetDrivenSaveUnlocked(address user, uint256 saveId, bool completed);

    // TYPES

    /**
     * saveId - the user target driven save id
     * reason - the reason for starting the save
     * amount - the amount to start the save with
     * targetAmount - the amount the user wishes to save up to
     * startTime - the time the user started the saving
     * stopTime - the time the user intends to stop the savings
     * completed - the status of the savings i.e true if the target has been met
     */
    struct TargetDrivenSavings {
        uint256 saveId;
        string reason;
        uint256 amount;
        uint256 targetAmount;
        uint256 startTime;
        uint256 stopTime;
        bool completed;
    }

    IERC20 MTRG;

    // STORAGE

    mapping(address user => TargetDrivenSavings[]) _userSavings;
    mapping(address user => uint256) _idCounter;

    // MODIFIERS
    modifier amountNotZero(uint256 _amount) {
        if (_amount == 0) {
            revert TargetDrivenSave__AmountCannnotBeZero();
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
     * Creates a target driven save which unlock condition can be of 3 types depending on the params passed
     * - Solely Amount Driven
     * - Solely Time Driven
     * - Both Amount & Time Driven
     * @param _reason the reason behind the target savings
     * @param _amount the amount to start the savings with
     * @param _targetAmount the target amount the user wishes to save up to
     * @param _time the time before the savings can be unlocked
     */
    function createTargetDrivenSave(string memory _reason, uint256 _amount, uint256 _targetAmount, uint256 _time)
        external
        nonReentrant
        amountNotZero(_amount)
    {
        if (_targetAmount == 0 && _time == 0) {
            revert TargetDrivenSave__AtLeastOneConditionMustBeSet();
        }

        if ((_time > 0 && _targetAmount > 0) || (_time == 0 && _targetAmount > 0)) {
            if (_targetAmount <= _amount) {
                revert TargetDrivenSave__TargetAmountMustBeGreaterThanStartAmount();
            }
        }

        SafeERC20.safeTransferFrom(MTRG, msg.sender, address(this), _amount);
        uint256 saveId = _idCounter[msg.sender] += 1;

        _userSavings[msg.sender].push(
            TargetDrivenSavings({
                saveId: saveId,
                reason: _reason,
                amount: _amount,
                targetAmount: _targetAmount,
                startTime: block.timestamp,
                stopTime: _time == 0 ? 0 : block.timestamp + _time,
                completed: false
            })
        );

        emit TargetDrivenSaveCreated(
            msg.sender,
            saveId,
            _reason,
            _amount,
            _targetAmount,
            block.timestamp,
            _time == 0 ? 0 : block.timestamp + _time,
            false
        );
    }

    /**
     * Top Up the target driven save amount to allow the user save more or reach their savings target
     * @param _saveId The save Id of the target driven save
     * @param _amount the amount the user wishes to top up with
     */
    function topUpTargetDrivenSave(uint256 _saveId, uint256 _amount) external nonReentrant amountNotZero(_amount) {
        if (_saveId > _idCounter[msg.sender]) {
            revert TargetDrivenSave__SaveDoesNotExist();
        }
        if (_userSavings[msg.sender][_saveId - 1].completed) {
            revert TargetDrivenSave__SaveAlreadyUnlocked();
        }

        SafeERC20.safeTransferFrom(MTRG, msg.sender, address(this), _amount);

        _userSavings[msg.sender][_saveId - 1].amount += _amount;

        emit TargetDrivenSaveToppedUp(msg.sender, _saveId, _amount);
    }

    /**
     * Unlocks and transfers the users target driven save funds so far the conditions are satisified
     * @param _saveId the users target driven save Id
     */
    function unlockTargetDrivenSave(uint256 _saveId) external nonReentrant {
        if (_saveId > _idCounter[msg.sender]) {
            revert TargetDrivenSave__SaveDoesNotExist();
        }
        if (_userSavings[msg.sender][_saveId - 1].completed) {
            revert TargetDrivenSave__SaveAlreadyUnlocked();
        }

        _checkTargetConditions(_saveId);

        _userSavings[msg.sender][_saveId - 1].completed = true;

        uint256 returnAmount = _userSavings[msg.sender][_saveId - 1].amount;
        SafeERC20.safeTransfer(MTRG, msg.sender, returnAmount);

        emit TargetDrivenSaveUnlocked(msg.sender, _saveId, true);
    }

    // INTERNAL FUNCTIONS

    /**
     * Checks for both the satisfaction of time and amount savings conditions and reverts if exists and not met
     * @param _saveId the target driven savings id
     */
    function _checkTargetConditions(uint256 _saveId) internal view {
        TargetDrivenSavings memory targetDrivenSavings = _userSavings[msg.sender][_saveId - 1];

        if (targetDrivenSavings.targetAmount > 0) {
            if (targetDrivenSavings.amount < targetDrivenSavings.targetAmount) {
                revert TargetDrivenSave__AmountTargetConditionNotSatisfied();
            }
        }

        if (targetDrivenSavings.stopTime > 0) {
            if (block.timestamp < targetDrivenSavings.stopTime) {
                revert TargetDrivenSave__TimeConditionNotSatisfied();
            }
        }
    }

    // GETTER FUNCTIONS

    /**
     * Gets a users target driven save by its id
     * @param _user the address of the user
     * @param _saveId the id of the target driven save
     */
    function getUserTargetDrivenSaving(address _user, uint256 _saveId)
        public
        view
        returns (TargetDrivenSavings memory)
    {
        return _userSavings[_user][_saveId - 1];
    }

    /**
     * Gets all user's target driven save
     * @param _user the address of the user
     */
    function getUserAllTargetDrivenSaving(address _user) public view returns (TargetDrivenSavings[] memory) {
        return _userSavings[_user];
    }

    /**
     * Gets the total number of target driven savings a user has ever created
     * @param _user the address of the user
     */
    function getUsersTargetDrivenSaveCount(address _user) public view returns (uint256) {
        return _idCounter[_user];
    }

    /**
     * gets the current timestamp
     */
    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}
