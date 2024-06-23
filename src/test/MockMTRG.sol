// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {MockERC20} from "forge-std/mocks/MockERC20.sol";

contract MockMTRG is MockERC20 {
    constructor() {
        initialize("Mock MTRG", "MMTRG", 18);
    }

    function mintToUser(address _user, uint256 _amount) public {
        _mint(_user, _amount);
    }
}
