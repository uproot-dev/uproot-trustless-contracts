
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IStudentAnswer {
    function getOwner() external view returns (address);

    function getSeed() external view returns (bytes32);
}
