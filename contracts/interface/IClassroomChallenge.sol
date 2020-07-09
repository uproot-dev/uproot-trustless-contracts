
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;


//TODO: map all attack vectors

interface IClassroomChallenge {
    function hintsCount() external pure returns (uint256);

    function getHint(uint256, bytes32) external view returns (bytes32);

    function viewMaterial() external pure returns (string memory);
}
