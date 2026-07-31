// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/AcademicCredit.sol";
import "../src/CourseAchievement.sol";
import "../src/DegreeSBT.sol";
import "../src/MerkleVerifier.sol";
import "../src/AcademicCredentialManager.sol";
import "../src/PremintERC20.sol";
import "../src/ChannelHub.sol";

contract Deploy is Script {

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
            PremintERC20 premintToken =
    new PremintERC20(
        "Nitrolite Token",
        "NIT",
        18,
        admin,
        1000000 ether
    );
AcademicCredentialManager manager =
    new AcademicCredentialManager(
        address(academicCredit),
        address(courseAchievement),
        address(degreeSBT),
        address(merkleVerifier)
    );
  
        vm.stopBroadcast();

        console.log("--------------------------------");
        console.log("Deployment Successful");
        console.log("--------------------------------");

        console.log(
            "AcademicCredit:",
            address(academicCredit)
        );

        console.log(
            "CourseAchievement:",
            address(courseAchievement)
        );

        console.log(
            "DegreeSBT:",
            address(degreeSBT)
        );

        console.log(
            "MerkleVerifier:",
            address(merkleVerifier)
        );
        console.log(
    "PremintERC20:",
    address(premintToken)
);
console.log(
    "AcademicCredentialManager:",
    address(manager)
);
    }
}