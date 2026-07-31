// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/AcademicCredentialManager.sol";
import "../src/AcademicCredit.sol";
import "../src/CourseAchievement.sol";
import "../src/DegreeSBT.sol";

contract VerifyAcademicRecord is Script {

    address constant STUDENT =
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    AcademicCredentialManager manager =
        AcademicCredentialManager(
            0x9A676e781A523b5d0C0e43731313A708CB607508
        );

    AcademicCredit credit =
        AcademicCredit(
            0x610178dA211FEF7D417bC0e6FeD39F05609AD788
        );

    CourseAchievement course =
        CourseAchievement(
            0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e
        );

    DegreeSBT degree =
        DegreeSBT(
            0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0
        );

    function run() external view {

        console.log("--------------------------------");
        console.log("Academic Credential Verification");
        console.log("--------------------------------");

        (
    bool registered,
    bytes32 merkleLeaf,
    uint256 totalCredits,
    uint256 degreeTokenId
) = manager.getStudent(STUDENT);

        console.log("Student:");
        console.log(STUDENT);

        console.log("Registered:");
        console.log(registered);

        console.log("Total Credits:");
        console.log(totalCredits);

        console.log("Degree Token ID:");
        console.log(degreeTokenId);

        console.log("--------------------------------");

        console.log("ERC20 Credit Balance:");
        console.log(credit.balanceOf(STUDENT));

        console.log("--------------------------------");

        console.log("Course Achievement (Course ID 101):");
        console.log(course.balanceOf(STUDENT, 101));

        console.log("--------------------------------");

        console.log("Degree Owner:");

        if (degree.ownerOf(degreeTokenId) == STUDENT) {
            console.log("Verified");
        } else {
            console.log("Mismatch");
        }

        console.log("--------------------------------");

        console.log("Merkle Leaf:");
        console.logBytes32(merkleLeaf);

        console.log("--------------------------------");
    }
}