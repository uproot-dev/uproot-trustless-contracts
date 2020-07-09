
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;

interface IStudentFactory {

    function newStudent(bytes32, address payable) external returns (address);
    
}