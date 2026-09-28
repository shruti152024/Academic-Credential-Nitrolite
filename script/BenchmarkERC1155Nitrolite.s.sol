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


contract BenchmarkERC1155Nitrolite is Script {

    uint256 constant NODE_PK = 1;
    uint256 constant ALICE_PK = 2;

    uint32 constant CHALLENGE_DURATION = 86400;
    uint64 constant NONCE = 1;

    uint256 constant INITIAL_BALANCE = 10000;
    uint256 constant CHANNEL_AMOUNT = 1000;

    uint256 constant TOTAL = 500;
    uint256 constant BATCH_SIZE = 100;

    uint256 constant COURSE_ID = 101;

 function run() external {

    uint256 nodePk = vm.envUint("NODE_PK");
    uint256 alicePk = vm.envUint("ALICE_PK");

    address node = vm.addr(nodePk);
    address alice = vm.addr(alicePk);

    vm.startBroadcast(alicePk);


        CourseAchievement achievement =
            new CourseAchievement(alice);




        ECDSAValidator validator =
            new ECDSAValidator();


      

        ChannelHub channelHub =
            new ChannelHub(
                validator,
                node
            );


      


        PremintERC20 settlementToken =
            new PremintERC20(
                "Nitrolite Academic Settlement Token",
                "NAST",
                18,
                alice,
                INITIAL_BALANCE
            );


        

        settlementToken.approve(
            address(channelHub),
            CHANNEL_AMOUNT
        );



        ChannelDefinition memory def =
            ChannelDefinition({
                challengeDuration: CHALLENGE_DURATION,
                user: alice,
                node: node,
                nonce: NONCE,
                approvedSignatureValidators: 0,
                metadata: keccak256(
                    abi.encode(
                        "ERC1155-NITROLITE",
                        address(achievement),
                        COURSE_ID
                    )
                )
            });


        

        bytes32 channelId =
            Utils.getChannelId(
                def,
                1
            );



        State memory state =
            State({
                version: 1,

                intent: StateIntent.DEPOSIT,

                metadata: keccak256(
                    abi.encode(
                        "ERC1155-NITROLITE-INITIAL",
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


       

        state.userSig =
            TestUtils.signStateEip191WithEcdsaValidator(
                vm,
                channelId,
                state,
                alicePk
            );


       

        state.nodeSig =
    TestUtils.signStateEip191WithEcdsaValidator(
        vm,
        channelId,
        state,
        nodePk
    );



        channelHub.createChannel(
            def,
            state
        );


      
        // 12. ERC-1155 batch issuance + Nitrolite checkpoint
        //
        // Each batch contains 100 academic credentials.
        //
        // After each ERC-1155 batch, a signed Nitrolite state
        // commits to that credential batch through metadata.
      

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



            achievement.batchIssueCourseAchievement(
                students,
                COURSE_ID,
                ipfsCIDs
            );


            
            // Create a cryptographic commitment to this credential
            // batch.
            //
            // The ERC-1155 token itself remains on-chain.
            // Nitrolite records the associated settlement state.
            

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


            

            state =
                TestUtils.nextState(
                    state,
                    StateIntent.OPERATE,
                    [CHANNEL_AMOUNT, uint256(0)],
                    [int256(CHANNEL_AMOUNT), int256(0)]
                );


            // Store credential-batch commitment in state metadata
            state.metadata =
                batchCommitment;


          

           state.userSig =
    TestUtils.signStateEip191WithEcdsaValidator(
        vm,
        channelId,
        state,
        alicePk
    );


           

            state.nodeSig =
    TestUtils.signStateEip191WithEcdsaValidator(
        vm,
        channelId,
        state,
        nodePk
    );


            channelHub.checkpointChannel(
                channelId,
                state
            );
        }


        vm.stopBroadcast();
    }
}