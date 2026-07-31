// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

import "../src/AcademicCredit.sol";
import "../src/CourseAchievement.sol";
import "../src/DegreeSBT.sol";

contract Benchmark is Script {

    function run() external {

        vm.startBroadcast();

        address admin = msg.sender;

        AcademicCredit credit =
            new AcademicCredit(admin);

        CourseAchievement achievement =
            new CourseAchievement(admin);

        DegreeSBT degree =
            new DegreeSBT(admin);

        uint256 TOTAL = 750;

        for(uint256 i = 1; i <= TOTAL; i++) {

            address student =
                address(uint160(i));

            credit.issueCredits(
                student,
                20
            );

            achievement.issueCourseAchievement(
                student,
                101,
                "ipfs://course"
            );

            degree.issueDegree(
                student,
                i
            );
        }

        vm.stopBroadcast();
    }
}