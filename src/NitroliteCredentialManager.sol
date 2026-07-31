// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./AcademicCredentialManager.sol";
import "./ChannelHub.sol";

contract NitroliteCredentialManager {

    AcademicCredentialManager public academicManager;
    ChannelHub public channelHub;

    address public university;

    struct TransferRequest {
        address student;
        uint256 credits;
        uint256 courseId;
        string ipfsCID;
        uint256 degreeTokenId;
        bool settled;
    }

    uint256 public transferCounter;

    mapping(uint256 => TransferRequest) public transfers;

    event CredentialTransferRequested(
        uint256 indexed transferId,
        address indexed student,
        uint256 credits,
        uint256 courseId
    );

    event CredentialTransferSettled(
        uint256 indexed transferId,
        address indexed student
    );

    modifier onlyUniversity() {
        require(msg.sender == university, "Only university");
        _;
    }

    constructor(
        address academicManagerAddress,
        address channelHubAddress
    ) {
        university = msg.sender;

        academicManager =
            AcademicCredentialManager(academicManagerAddress);

        channelHub =
            ChannelHub(channelHubAddress);
    }

    function requestCredentialTransfer(
        address student,
        uint256 credits,
        uint256 courseId,
        string calldata ipfsCID,
        uint256 degreeTokenId
    )
        external
        onlyUniversity
    {
        transferCounter++;

        transfers[transferCounter] = TransferRequest({
            student: student,
            credits: credits,
            courseId: courseId,
            ipfsCID: ipfsCID,
            degreeTokenId: degreeTokenId,
            settled: false
        });

        emit CredentialTransferRequested(
            transferCounter,
            student,
            credits,
            courseId
        );
    }

    function settleCredentialTransfer(
        uint256 transferId
    )
        external
        onlyUniversity
    {
        TransferRequest storage t = transfers[transferId];

        require(!t.settled, "Already settled");

        academicManager.issueAcademicRecord(
            t.student,
            t.credits,
            t.courseId,
            t.ipfsCID,
            t.degreeTokenId
        );

        t.settled = true;

        emit CredentialTransferSettled(
            transferId,
            t.student
        );
    }

    function getTransfer(
        uint256 transferId
    )
        external
        view
        returns(
            address student,
            uint256 credits,
            uint256 courseId,
            string memory ipfsCID,
            uint256 degreeTokenId,
            bool settled
        )
    {
        TransferRequest memory t = transfers[transferId];

        return (
            t.student,
            t.credits,
            t.courseId,
            t.ipfsCID,
            t.degreeTokenId,
            t.settled
        );
    }
}