// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/AcademicCredit.sol";
import "../src/CourseAchievement.sol";
import "../src/DegreeSBT.sol";

contract GrantRoles is Script {

    function run() external {

        vm.startBroadcast();

        // Deployed contract addresses
        AcademicCredit academicCredit =
            AcademicCredit(0x610178dA211FEF7D417bC0e6FeD39F05609AD788);

        CourseAchievement courseAchievement =
            CourseAchievement(0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e);

        DegreeSBT degreeSBT =
            DegreeSBT(0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0);

        address manager =
            0x9A676e781A523b5d0C0e43731313A708CB607508;

        academicCredit.grantRole(
            academicCredit.CREDIT_ISSUER_ROLE(),
            manager
        );

        courseAchievement.grantRole(
            courseAchievement.COURSE_ISSUER_ROLE(),
            manager
        );

        degreeSBT.grantRole(
            degreeSBT.DEGREE_ISSUER_ROLE(),
            manager
        );

        console.log("Roles granted successfully.");

        vm.stopBroadcast();
    }
}