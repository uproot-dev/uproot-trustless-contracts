
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;

interface IStudentApplicationFactory {

    function newStudentApplication(
        address,
        address,
        address,
        address,
        address,
        bytes32
    ) external returns (address);
    
}