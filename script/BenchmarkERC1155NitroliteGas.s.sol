// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {CourseAchievement} from "../src/CourseAchievement.sol";
import {ChannelHub} from "../src/ChannelHub.sol";
import {PremintERC20} from "../src/PremintERC20.sol";
import {ECDSAValidator} from "../src/sigValidators/ECDSAValidator.sol";

import {
    ChannelDefinition,
    State,
    Ledger,
    StateIntent
} from "../src/interfaces/Types.sol";

import {Utils} from "../src/Utils.sol";
import {TestUtils} from "../test/TestUtils.sol";


contract BenchmarkERC1155NitroliteGas is Script {

    // ============================================================
    // Benchmark configuration
    // ============================================================

    uint256 constant NODE_PK = 1;
    uint256 constant ALICE_PK = 2;

    uint32 constant CHALLENGE_DURATION = 86400;
    uint64 constant NONCE = 1;

    uint256 constant INITIAL_BALANCE = 10000;
    uint256 constant CHANNEL_AMOUNT = 1000;

    uint256 constant TOTAL = 100;
    uint256 constant BATCH_SIZE = 100;

    uint256 constant COURSE_ID = 101;


    // ============================================================
    // Main benchmark
    // ============================================================

    function run() external {

        address node = vm.addr(NODE_PK);
        address alice = vm.addr(ALICE_PK);

        console2.log("==============================================");
        console2.log("ERC1155 + Nitrolite Gas Benchmark");
        console2.log("==============================================");

        console2.log("Total credentials:", TOTAL);
        console2.log("Batch size:", BATCH_SIZE);
        console2.log("Alice:", alice);
        console2.log("Node:", node);


        vm.startBroadcast(ALICE_PK);


        // ========================================================
        // 1. Deploy ERC-1155 academic credential contract
        // ========================================================

        CourseAchievement achievement =
            new CourseAchievement(alice);

        console2.log(
            "CourseAchievement:",
            address(achievement)
        );


        // ========================================================
        // 2. Deploy Nitrolite signature validator
        // ========================================================

        ECDSAValidator validator =
            new ECDSAValidator();


        // ========================================================
        // 3. Deploy Nitrolite ChannelHub
        // ========================================================

        ChannelHub channelHub =
            new ChannelHub(
                validator,
                node
            );

        console2.log(
            "ECDSAValidator:",
            address(validator)
        );

        console2.log(
            "ChannelHub:",
            address(channelHub)
        );


        // ========================================================
        // 4. Deploy ERC-20 settlement asset
        //
        // Nitrolite ChannelHub uses an ERC-20/native settlement
        // asset. The ERC-1155 credential itself is not the
        // ChannelHub ledger asset.
        // ========================================================

        PremintERC20 settlementToken =
            new PremintERC20(
                "Nitrolite Academic Settlement Token",
                "NAST",
                18,
                alice,
                INITIAL_BALANCE
            );

        console2.log(
            "Settlement token:",
            address(settlementToken)
        );


        // ========================================================
        // 5. Approve ChannelHub to use settlement asset
        // ========================================================

        settlementToken.approve(
            address(channelHub),
            CHANNEL_AMOUNT
        );


        // ========================================================
        // 6. Create Nitrolite channel definition
        // ========================================================

        ChannelDefinition memory def =
            ChannelDefinition({
                challengeDuration: CHALLENGE_DURATION,
                user: alice,
                node: node,
                nonce: NONCE,
                approvedSignatureValidators: 0,
                metadata: keccak256(
                    abi.encode(
                        "ERC1155-NITROLITE-GAS",
                        address(achievement),
                        COURSE_ID
                    )
                )
            });


        // ========================================================
        // 7. Generate channel ID
        // ========================================================

        bytes32 channelId =
            Utils.getChannelId(
                def,
                1
            );

        console2.log("Channel ID:");
        console2.logBytes32(channelId);


        // ========================================================
        // 8. Create initial Nitrolite state
        // ========================================================

        State memory state =
            State({
                version: 1,

                intent: StateIntent.DEPOSIT,

                metadata: keccak256(
                    abi.encode(
                        "INITIAL-ERC1155-NITROLITE-GAS",
                        address(achievement),
                        COURSE_ID,
                        TOTAL
                    )
                ),

                homeLedger: Ledger({
                    chainId: uint64(block.chainid),
                    token: address(settlementToken),
                    decimals: 18,

                    userAllocation: CHANNEL_AMOUNT,
                    userNetFlow: int256(CHANNEL_AMOUNT),

                    nodeAllocation: 0,
                    nodeNetFlow: 0
                }),

                nonHomeLedger: Ledger({
                    chainId: 0,
                    token: address(0),
                    decimals: 0,

                    userAllocation: 0,
                    userNetFlow: 0,

                    nodeAllocation: 0,
                    nodeNetFlow: 0
                }),

                userSig: "",
                nodeSig: ""
            });


        // ========================================================
        // 9. Sign initial state by Alice
        // ========================================================

        state.userSig =
            TestUtils.signStateEip191WithEcdsaValidator(
                vm,
                channelId,
                state,
                ALICE_PK
            );


        // ========================================================
        // 10. Sign initial state by Node
        // ========================================================

        state.nodeSig =
            TestUtils.signStateEip191WithEcdsaValidator(
                vm,
                channelId,
                state,
                NODE_PK
            );


        // ========================================================
        // 11. Create Nitrolite channel
        // ========================================================

        channelHub.createChannel(
            def,
            state
        );

        console2.log(
            "Nitrolite channel created."
        );


        // ========================================================
        // 12. Process ERC-1155 batches
        //
        // Each batch contains up to 100 academic credentials.
        //
        // The ERC-1155 credentials remain on-chain.
        //
        // After each batch, a cryptographic commitment is placed
        // in the Nitrolite state metadata and checkpointed.
        // ========================================================

        for (
            uint256 start = 0;
            start < TOTAL;
            start += BATCH_SIZE
        ) {

            uint256 remaining =
                TOTAL - start;

            uint256 currentBatchSize =
                remaining < BATCH_SIZE
                    ? remaining
                    : BATCH_SIZE;


            // ====================================================
            // 13. Prepare student addresses and IPFS CIDs
            // ====================================================

            address[] memory students =
                new address[](currentBatchSize);

            string[] memory ipfsCIDs =
                new string[](currentBatchSize);


            for (
                uint256 i = 0;
                i < currentBatchSize;
                i++
            ) {

                uint256 studentNumber =
                    start + i + 1;

                students[i] =
                    address(uint160(studentNumber));

                ipfsCIDs[i] =
                    "ipfs://course";
            }


            // ====================================================
            // 14. ERC-1155 batch issuance
            // ====================================================

            achievement.batchIssueCourseAchievement(
                students,
                COURSE_ID,
                ipfsCIDs
            );

            console2.log(
                "ERC1155 batch issuance completed."
            );


            // ====================================================
            // 15. Generate cryptographic batch commitment
            // ====================================================

            bytes32 batchCommitment =
                keccak256(
                    abi.encode(
                        address(achievement),
                        COURSE_ID,
                        start + 1,
                        start + currentBatchSize,
                        students
                    )
                );

            console2.log(
                "Batch commitment:"
            );

            console2.logBytes32(
                batchCommitment
            );


            // ====================================================
            // 16. Generate next Nitrolite state
            // ====================================================

            state =
                TestUtils.nextState(
                    state,
                    StateIntent.OPERATE,
                    [CHANNEL_AMOUNT, uint256(0)],
                    [int256(CHANNEL_AMOUNT), int256(0)]
                );


            // ====================================================
            // 17. Store credential-batch commitment
            // ====================================================

            state.metadata =
                batchCommitment;


            // ====================================================
            // 18. Sign updated state by Alice
            // ====================================================

            state.userSig =
                TestUtils.signStateEip191WithEcdsaValidator(
                    vm,
                    channelId,
                    state,
                    ALICE_PK
                );


            // ====================================================
            // 19. Sign updated state by Node
            // ====================================================

            state.nodeSig =
                TestUtils.signStateEip191WithEcdsaValidator(
                    vm,
                    channelId,
                    state,
                    NODE_PK
                );


            // ====================================================
            // 20. Checkpoint updated Nitrolite state
            // ====================================================

            channelHub.checkpointChannel(
                channelId,
                state
            );

            console2.log(
                "Nitrolite checkpoint completed."
            );
        }


        console2.log("==============================================");
        console2.log("Benchmark completed successfully");
        console2.log("==============================================");


        vm.stopBroadcast();
    }
}