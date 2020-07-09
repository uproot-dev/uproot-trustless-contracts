
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;


interface IClassroomFactory {
    function newClassroom(
        bytes32,
        uint24,
        uint24,
        int32,
        uint256,
        uint256,
        address payable,
        address,
        address,
        address,
        address
    ) external returns (address);
}
