// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.11;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@nomiclabs/buidler/console.sol";
//import "@nomiclabs/buidler/console.sol";
import "./interface/IStudent.sol";
import "./interface/IClassroom.sol";
import "./interface/IUniversity.sol";
import "./interface/IStudentApplication.sol";
import "./interface/IGrantsManager.sol";

contract Student is Ownable, AccessControl, IStudent {
    using SafeMath for uint256;

    //READ_SCORE_ROLE can read student Score
    bytes32 public constant READ_SCORE_ROLE = keccak256("READ_SCORE_ROLE");
    //MODIFY_SCORE_ROLE can read student Score
    bytes32 public constant MODIFY_SCORE_ROLE = keccak256("MODIFY_SCORE_ROLE");

    bytes32 public name;
    IUniversity public university;
    address[] public classroomAddresses;
    int32 _score;

    constructor(bytes32 _name, address payable universityAddress) public {
        name = _name;
        _score = 0;
        university = IUniversity(universityAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(MODIFY_SCORE_ROLE, universityAddress);
        if (_msgSender() != universityAddress) {
            grantRole(READ_SCORE_ROLE, universityAddress);
            grantRole(DEFAULT_ADMIN_ROLE, universityAddress);
            renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
    }

    event LogChangeName(bytes32);

    function ownerStudent() public override view returns (address) {
        return owner();
    }

    function transferOwnershipStudent(address newOwner) public override {
        grantRole(READ_SCORE_ROLE, newOwner);
        transferOwnership(newOwner);
    }

    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    function score() public override view returns (int32) {
        require(
            hasRole(READ_SCORE_ROLE, _msgSender()),
            "Student: caller doesn't have READ_SCORE_ROLE"
        );
        return _score;
    }

    function addScore(int32 val) public override {
        require(
            hasRole(MODIFY_SCORE_ROLE, _msgSender()),
            "Student: caller doesn't have MODIFY_SCORE_ROLE"
        );
        require(_score < _score + val, "Student: good grades overflow");
        _score += val;
    }

    function subScore(int32 val) public override {
        require(
            hasRole(MODIFY_SCORE_ROLE, _msgSender()),
            "Student: caller doesn't have MODIFY_SCORE_ROLE"
        );
        require(_score > _score - val, "Student: bad grades overflow");
        _score -= val;
    }

    function applyToClassroom(address classroomAddress) public onlyOwner {
        require(
            university.isValidClassroom(classroomAddress),
            "Student: address is not a valid classroom"
        );
        _setupRole(READ_SCORE_ROLE, classroomAddress);
        IClassroom(classroomAddress).studentApply();
        classroomAddresses.push(classroomAddress);
    }

    function setAnswerSecret(address classroomAddress, bytes32 secret)
        public
        onlyOwner
    {
        IStudentApplication(viewMyApplication(classroomAddress))
            .setAnswerSecret(secret);
    }

    function viewChallengeMaterial(address classroomAddress)
        public
        view
        onlyOwner
        returns (string memory)
    {
        return
            IStudentApplication(viewMyApplication(classroomAddress))
                .viewChallengeMaterial();
    }

    function viewMyApplication(address classroomAddress)
        public
        view
        onlyOwner
        returns (address)
    {
        require(
            university.isValidClassroom(classroomAddress),
            "Student: address is not a valid classroom"
        );
        return IClassroom(classroomAddress).viewMyApplication();
    }

    function viewMyApplicationState(address classroomAddress)
        public
        view
        onlyOwner
        returns (uint256)
    {
        require(
            university.isValidClassroom(classroomAddress),
            "Student: address is not a valid classroom"
        );
        address app = IClassroom(classroomAddress).viewMyApplication();
        return IStudentApplication(app).applicationState();
    }

    function refundApplicationFromClassroom(address classroom, address to)
        public
        onlyOwner
    {
        refundApplication(IClassroom(classroom).viewMyApplication(), to);
    }

    function withdrawAllResultsFromClassroom(address classroom, address to)
        public
        onlyOwner
    {
        withdrawAllResultsFromApplication(
            IClassroom(classroom).viewMyApplication(),
            to
        );
    }

    function withdrawResultsFromClassroom(
        address classroom,
        address to,
        uint256 val
    ) public onlyOwner {
        withdrawResultsFromApplication(
            IClassroom(classroom).viewMyApplication(),
            to,
            val
        );
    }

    function refundApplication(address application, address to)
        public
        onlyOwner
    {
        IStudentApplication(application).refundPayment(to);
    }

    function withdrawAllResultsFromApplication(address application, address to)
        public
        onlyOwner
    {
        IStudentApplication(application).withdrawAllResults(to);
    }

    function withdrawResultsFromApplication(
        address application,
        address to,
        uint256 val
    ) public onlyOwner {
        IStudentApplication(application).withdraw(to, val);
    }

    function requestGrant(address grantsManager, address studentApplication)
        public
        onlyOwner
    {
        require(
            IStudentApplication(studentApplication).studentAddress() ==
                address(this),
            "Student: wrong application address"
        );
        uint256 price = IStudentApplication(studentApplication).entryPrice();
        _setupRole(READ_SCORE_ROLE, grantsManager);
        require(
            IGrantsManager(grantsManager).studentRequestGrant(
                price,
                studentApplication
            ),
            "Student: grant denied"
        );
    }
}
