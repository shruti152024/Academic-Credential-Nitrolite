// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./AcademicCredit.sol";
import "./CourseAchievement.sol";
import "./DegreeSBT.sol";
import "./MerkleVerifier.sol";

contract AcademicCredentialManager {

    AcademicCredit public academicCredit;
    CourseAchievement public courseAchievement;
    DegreeSBT public degreeSBT;
    MerkleVerifier public merkleVerifier;

    address public university;

    struct Student {
        bool registered;
        bytes32 merkleLeaf;
        uint256 totalCredits;
        uint256 degreeTokenId;
    }

    mapping(address => Student) public students;

    event StudentRegistered(
        address indexed student,
        bytes32 merkleLeaf
    );

    event AcademicRecordIssued(
        address indexed student,
        uint256 credits,
        uint256 courseId,
        uint256 degreeTokenId
    );

    modifier onlyUniversity() {
        require(msg.sender == university, "Only university");
        _;
    }

    constructor(
        address credit,
        address achievement,
        address degree,
        address verifier
    ) {
        university = msg.sender;

        academicCredit = AcademicCredit(credit);
        courseAchievement = CourseAchievement(achievement);
        degreeSBT = DegreeSBT(degree);
        merkleVerifier = MerkleVerifier(verifier);
    }

    function registerStudent(
        address student,
        bytes32 leaf
    )
        external
        onlyUniversity
    {
        require(student != address(0), "Invalid student");

        require(
            !students[student].registered,
            "Already registered"
        );

        students[student] = Student({
            registered: true,
            merkleLeaf: leaf,
            totalCredits: 0,
            degreeTokenId: 0
        });

        emit StudentRegistered(student, leaf);
    }

    function issueAcademicRecord(
        address student,
        uint256 credits,
        uint256 courseId,
        string calldata ipfsCID,
        uint256 degreeTokenId
    )
        external
        onlyUniversity
    {
        require(
            students[student].registered,
            "Student not registered"
        );

        academicCredit.issueCredits(
            student,
            credits
        );

        courseAchievement.issueCourseAchievement(
            student,
            courseId,
            ipfsCID
        );

        if (students[student].degreeTokenId == 0) {

            degreeSBT.issueDegree(
                student,
                degreeTokenId
            );

            students[student].degreeTokenId =
                degreeTokenId;
        }

        students[student].totalCredits += credits;

        emit AcademicRecordIssued(
            student,
            credits,
            courseId,
            degreeTokenId
        );
    }

    function getStudent(
        address student
    )
        external
        view
        returns (
            bool registered,
            bytes32 merkleLeaf,
            uint256 totalCredits,
            uint256 degreeTokenId
        )
    {
        Student memory s = students[student];

        return (
            s.registered,
            s.merkleLeaf,
            s.totalCredits,
            s.degreeTokenId
        );
    }
}