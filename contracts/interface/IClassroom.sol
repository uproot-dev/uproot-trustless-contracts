
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;

interface IClassroom {

    function entryPrice() external view returns (uint256);

    function transferOwnershipClassroom(address) external;
    
    function studentApply() external;

    function viewMyApplication() external view returns (address);

    function ownerClassroom() external view returns (address);
}