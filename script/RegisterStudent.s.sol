// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/AcademicCredentialManager.sol";

contract RegisterStudent is Script {

    function run() external {

        vm.startBroadcast();

        // AcademicCredentialManager deployed address
        AcademicCredentialManager manager =
            AcademicCredentialManager(
                0x9A676e781A523b5d0C0e43731313A708CB607508
            );

        // Test student address
        address student =
            0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        // Sample Merkle leaf
        bytes32 leaf =
            keccak256(
                abi.encodePacked(
                    student,
                    "STU001",
                    "Shruti Tripathi"
                )
            );

        manager.registerStudent(
            student,
            leaf
        );

        console.log("--------------------------------");
        console.log("Student Registered Successfully");
        console.log("--------------------------------");

        console.log("Student:");
        console.log(student);

        console.logBytes32(leaf);

        vm.stopBroadcast();
    }
}