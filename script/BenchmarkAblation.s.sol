// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

import "../src/CourseAchievement.sol";
import "../src/DegreeSBT.sol";

contract BenchmarkAblation is Script {

    uint256 constant TOTAL = 1000;

   
    function runERC721() external {
        vm.startBroadcast();

        address admin = msg.sender;

        DegreeSBT degree =
            new DegreeSBT(admin);

        for (uint256 i = 1; i <= TOTAL; i++) {

            address student =
                address(uint160(i));

            degree.issueDegree(
                student,
                i
            );
        }

        vm.stopBroadcast();
    }

   
    function runERC1155Individual() external {
        vm.startBroadcast();

        address admin = msg.sender;

        CourseAchievement achievement =
            new CourseAchievement(admin);

        for (uint256 i = 1; i <= TOTAL; i++) {

            address student =
                address(uint160(i));

            achievement.issueCourseAchievement(
                student,
                101,
                "ipfs://course"
            );
        }

        vm.stopBroadcast();
    }

  
    function runERC1155Batch() external {
    vm.startBroadcast();

    address admin = msg.sender;

    CourseAchievement achievement =
        new CourseAchievement(admin);

    uint256 batchSize = 100;

    for (uint256 start = 0; start < TOTAL; start += batchSize) {

        uint256 remaining = TOTAL - start;
        uint256 currentBatchSize =
            remaining < batchSize ? remaining : batchSize;

        address[] memory students =
            new address[](currentBatchSize);

        string[] memory ipfsCIDs =
            new string[](currentBatchSize);

        for (uint256 i = 0; i < currentBatchSize; i++) {

            uint256 studentNumber = start + i + 1;

            students[i] =
                address(uint160(studentNumber));

            ipfsCIDs[i] =
                "ipfs://course";
        }

                achievement.batchIssueCourseAchievement(
            students,
            101,
            ipfsCIDs
        );
    }

    vm.stopBroadcast();
}
}