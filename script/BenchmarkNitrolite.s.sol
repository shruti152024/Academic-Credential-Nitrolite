// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";

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

contract BenchmarkNitrolite is Script {

    uint256 constant NODE_PK = 1;
    uint256 constant ALICE_PK = 2;

    uint32 constant CHALLENGE_DURATION = 86400;
    uint64 constant NONCE = 1;

    uint256 constant INITIAL_BALANCE = 10000;
    uint256 constant CHANNEL_AMOUNT = 1000;

    uint256 constant TOTAL = 1000;

    function run() external {

        address node = vm.addr(NODE_PK);
        address alice = vm.addr(ALICE_PK);

        // All transactions in this benchmark are broadcast from Alice.
        vm.startBroadcast(ALICE_PK);

        // ------------------------------------------------------------
        // 1. Deploy ECDSA validator
        // ------------------------------------------------------------
        ECDSAValidator validator = new ECDSAValidator();

        // ------------------------------------------------------------
        // 2. Deploy ChannelHub
        // ------------------------------------------------------------
        ChannelHub channelHub = new ChannelHub(
            validator,
            node
        );

        // ------------------------------------------------------------
        // 3. Deploy ERC-20 settlement token
        //
        // This token is used only for the Nitrolite state-channel
        // benchmark. It is NOT the ERC-1155 academic credential.
        // ------------------------------------------------------------
        PremintERC20 token = new PremintERC20(
            "Nitrolite Benchmark Token",
            "NBT",
            18,
            alice,
            INITIAL_BALANCE
        );

        // ------------------------------------------------------------
        // 4. Alice approves ChannelHub
        // ------------------------------------------------------------
        token.approve(
            address(channelHub),
            CHANNEL_AMOUNT
        );

        // ------------------------------------------------------------
        // 5. Define the channel
        // ------------------------------------------------------------
        ChannelDefinition memory def = ChannelDefinition({
            challengeDuration: CHALLENGE_DURATION,
            user: alice,
            node: node,
            nonce: NONCE,
            approvedSignatureValidators: 0,
            metadata: bytes32(0)
        });

        // ------------------------------------------------------------
        // 6. Calculate channel ID
        // ------------------------------------------------------------
        bytes32 channelId = Utils.getChannelId(
            def,
            1
        );

        // ------------------------------------------------------------
        // 7. Construct initial channel state
        // ------------------------------------------------------------
        State memory state = State({
            version: 1,
            intent: StateIntent.DEPOSIT,
            metadata: bytes32(0),

            homeLedger: Ledger({
                chainId: uint64(block.chainid),
                token: address(token),
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

        // ------------------------------------------------------------
        // 8. Sign initial state by Alice
        // ------------------------------------------------------------
        state.userSig =
            TestUtils.signStateEip191WithEcdsaValidator(
                vm,
                channelId,
                state,
                ALICE_PK
            );

        // ------------------------------------------------------------
        // 9. Sign initial state by Node
        // ------------------------------------------------------------
        state.nodeSig =
            TestUtils.signStateEip191WithEcdsaValidator(
                vm,
                channelId,
                state,
                NODE_PK
            );

        // ------------------------------------------------------------
        // 10. Create channel
        // ------------------------------------------------------------
        channelHub.createChannel(
            def,
            state
        );

        // ------------------------------------------------------------
        // 11. Perform checkpoint operations
        //
        // TOTAL = 50 means 50 checkpoint operations after the
        // initial channel creation.
        // ------------------------------------------------------------
        for (uint256 i = 1; i <= TOTAL; i++) {

            state = TestUtils.nextState(
                state,
                StateIntent.OPERATE,
                [CHANNEL_AMOUNT, uint256(0)],
                [int256(CHANNEL_AMOUNT), int256(0)]
            );

            // Sign updated state by Alice
            state.userSig =
                TestUtils.signStateEip191WithEcdsaValidator(
                    vm,
                    channelId,
                    state,
                    ALICE_PK
                );

            // Sign updated state by Node
            state.nodeSig =
                TestUtils.signStateEip191WithEcdsaValidator(
                    vm,
                    channelId,
                    state,
                    NODE_PK
                );

            // Submit checkpoint
            channelHub.checkpointChannel(
                channelId,
                state
            );
        }

        vm.stopBroadcast();
    }
}
