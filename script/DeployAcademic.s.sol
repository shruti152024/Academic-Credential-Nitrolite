// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/AcademicCredit.sol";
import "../src/CourseAchievement.sol";
import "../src/DegreeSBT.sol";
import "../src/MerkleVerifier.sol";
import "../src/AcademicCredentialManager.sol";

contract DeployAcademic is Script {

    function run() external {

        vm.startBroadcast();

        address admin = msg.sender;

AcademicCredit academicCredit =
    new AcademicCredit(admin);

CourseAchievement courseAchievement =
    new CourseAchievement(admin);

DegreeSBT degreeSBT =
    new DegreeSBT(admin);

MerkleVerifier merkleVerifier =
    new MerkleVerifier(admin);

        AcademicCredentialManager manager =
            new AcademicCredentialManager(
                address(academicCredit),
                address(courseAchievement),
                address(degreeSBT),
                address(merkleVerifier)
            );

        vm.stopBroadcast();

        console.log("-------------------------------------");
        console.log("Academic Contracts Deployed");
        console.log("-------------------------------------");

        console.log("AcademicCredit:");
        console.log(address(academicCredit));

        console.log("CourseAchievement:");
        console.log(address(courseAchievement));

        console.log("DegreeSBT:");
        console.log(address(degreeSBT));

        console.log("MerkleVerifier:");
        console.log(address(merkleVerifier));

        console.log("AcademicCredentialManager:");
        console.log(address(manager));

        console.log("-------------------------------------");
    }
}