// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.11;

import "./interface/IStudentApplicationFactory.sol";
import "./StudentApplication.sol";


contract StudentApplicationFactory is IStudentApplicationFactory {
    function newStudentApplication(
        address studentAddress,
        address classroomAddress,
        address daiAddress,
        address challengeAddress,
        address universityAddress,
        bytes32 seed
    ) public override returns (address studentApplicationAddress) {
        StudentApplication studentApplication = new StudentApplication(
            studentAddress,
            classroomAddress,
            daiAddress,
            challengeAddress,
            universityAddress,
            seed
        );
        studentApplication.transferOwnership(msg.sender);
        studentApplicationAddress = address(studentApplication);
    }
}
