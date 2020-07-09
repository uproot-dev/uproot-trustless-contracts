
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;

interface IGrantsManager {

    function studentRequestGrant(uint256, address) external returns (bool);

    function viewAllStudents() external returns (address[] memory);

    function viewAllGrantsForStudent(address) external returns (uint256[] memory);
    
}