// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/AcademicCredentialManager.sol";

contract IssueAcademicRecord is Script {

    function run() external {

        vm.startBroadcast();

        // AcademicCredentialManager deployed address
        AcademicCredentialManager manager =
            AcademicCredentialManager(
                0x9A676e781A523b5d0C0e43731313A708CB607508
            );

        // Registered student
        address student =
            0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        uint256 credits = 20;
        uint256 courseId = 101;

        string memory ipfsCID =
            "Qmem8qigtQNNMimV3oHsCPVcKo1yA8eswgbYCEzh7CjRQq";

        uint256 degreeTokenId = 1;

        manager.issueAcademicRecord(
            student,
            credits,
            courseId,
            ipfsCID,
            degreeTokenId
        );

        console.log("--------------------------------");
        console.log("Academic Record Issued");
        console.log("--------------------------------");

        console.log("Student:");
        console.log(student);

        console.log("Credits:");
        console.log(credits);

        console.log("Course ID:");
        console.log(courseId);

        console.log("Degree Token:");
        console.log(degreeTokenId);

        vm.stopBroadcast();
    }
}