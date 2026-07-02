// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract CourseAchievement is ERC1155, AccessControl {
bytes32 public constant COURSE_ISSUER_ROLE =
    keccak256("COURSE_ISSUER_ROLE");
    constructor(address universityAdmin)
    ERC1155("")
{
    _grantRole(DEFAULT_ADMIN_ROLE, universityAdmin);
    _grantRole(COURSE_ISSUER_ROLE, universityAdmin);
}
mapping(uint256 => mapping(address => bool))
    public hasCourseAchievement;

mapping(uint256 => mapping(address => string))
    public courseCertificateCID;
    event CourseAchievementIssued(
    address indexed student,
    uint256 indexed courseId,
    string ipfsCID
);

event CourseAchievementRevoked(
    address indexed student,
    uint256 indexed courseId
);
function issueCourseAchievement(
    address student,
    uint256 courseId,
    string calldata ipfsCID
)
    external
    onlyRole(COURSE_ISSUER_ROLE)
{
    require(student != address(0), "Invalid student");
    require(student.code.length == 0, "Contracts not allowed");
    require(
        !hasCourseAchievement[courseId][student],
        "Already issued"
    );

    hasCourseAchievement[courseId][student] = true;

    _mint(student, courseId, 1, "");

    courseCertificateCID[courseId][student] = ipfsCID;

 emit CourseAchievementIssued(
    student,
    courseId,
    ipfsCID
);
}
    function batchIssueCourseAchievement(
    address[] calldata students,
    uint256 courseId,
    string[] calldata ipfsCIDs
)
    external
    onlyRole(COURSE_ISSUER_ROLE)
{
    require(
        students.length == ipfsCIDs.length,
        "Length mismatch"
    );

    for (uint256 i = 0; i < students.length; i++) {

        require(students[i] != address(0), "Invalid student");

        require(
            students[i].code.length == 0,
            "Contracts not allowed"
        );

        require(
            !hasCourseAchievement[courseId][students[i]],
            "Already issued"
        );

        hasCourseAchievement[courseId][students[i]] = true;

        _mint(students[i], courseId, 1, "");

        courseCertificateCID[courseId][students[i]] =
            ipfsCIDs[i];

        emit CourseAchievementIssued(
            students[i],
            courseId,
            ipfsCIDs[i]
        );
    }
}
function revokeCourseAchievement(
    address student,
    uint256 courseId
)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
{
    require(
        hasCourseAchievement[courseId][student],
        "Not issued"
    );

    hasCourseAchievement[courseId][student] = false;

    _burn(student, courseId, 1);

    delete courseCertificateCID[courseId][student];

    emit CourseAchievementRevoked(
        student,
        courseId
    );
}
function _update(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory values
)
    internal
    override
{
    if (from != address(0) && to != address(0)) {
        revert("Course achievements are non-transferable");
    }

    super._update(from, to, ids, values);
}



function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
{
    return super.supportsInterface(interfaceId);
}

} 

