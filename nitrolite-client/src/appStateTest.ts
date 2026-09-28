import "dotenv/config";

import {
  Client,
  createSigners,
  AppSessionWalletSignerV1,
  EthereumMsgSigner,
  packCreateAppSessionRequestV1,
  packAppStateUpdateV1,
  AppStateUpdateIntent,
  type AppDefinitionV1,
  type AppStateUpdateV1,
} from "@yellow-org/sdk";

const WS_URL =
  process.env.NITRONODE_WS_URL ??
  "wss://nitronode-sandbox.yellow.org/v1/ws";

const PK1 = process.env.TEST_PRIVATE_KEY as `0x${string}`;
const PK2 = process.env.TEST_PRIVATE_KEY_2 as `0x${string}`;

if (!PK1) {
  throw new Error("TEST_PRIVATE_KEY is missing from .env");
}

if (!PK2) {
  throw new Error("TEST_PRIVATE_KEY_2 is missing from .env");
}

async function main() {
  console.log("==============================================");
  console.log(" Nitronode V1 App State Smoke Test");
  console.log("==============================================");
  console.log("Nitronode URL:", WS_URL);
  console.log("");

  // ------------------------------------------------------------
  // 1. Create participant signers
  // ------------------------------------------------------------

  console.log("Creating participant signers...");

  const signer1 = createSigners(PK1);
  const signer2 = createSigners(PK2);

  // ------------------------------------------------------------
  // 2. Connect both participants
  // ------------------------------------------------------------

  console.log("Connecting participant 1...");

  const client1 = await Client.create(
    WS_URL,
    signer1.stateSigner,
    signer1.txSigner,
  );

  console.log("Participant 1 connected.");

  console.log("Connecting participant 2...");

  const client2 = await Client.create(
    WS_URL,
    signer2.stateSigner,
    signer2.txSigner,
  );

  console.log("Participant 2 connected.");
  console.log("");

  try {
    // ----------------------------------------------------------
    // 3. Get participant addresses
    // ----------------------------------------------------------

    const address1 = client1.getUserAddress();
    const address2 = client2.getUserAddress();

    console.log("Participant 1:", address1);
    console.log("Participant 2:", address2);
    console.log("");

    // ----------------------------------------------------------
    // 4. Create unique application ID
    // ----------------------------------------------------------

    const applicationId =
      `academic-credential-state-test-${Date.now().toString(36)}`
        .toLowerCase();

    console.log("Application ID:", applicationId);
    console.log("");

    // ----------------------------------------------------------
    // 5. Define two-participant application session
    // ----------------------------------------------------------

    const definition: AppDefinitionV1 = {
      applicationId,

      participants: [
        {
          walletAddress: address1,
          signatureWeight: 1,
        },
        {
          walletAddress: address2,
          signatureWeight: 1,
        },
      ],

      quorum: 2,

      nonce: BigInt(Date.now()),
    };

    console.log("Application definition created.");
    console.log("Participants:", definition.participants.length);
    console.log("Quorum:", definition.quorum);
    console.log("Nonce:", definition.nonce.toString());
    console.log("");

    // ----------------------------------------------------------
    // 6. Create application-session data
    // ----------------------------------------------------------

    const sessionData = JSON.stringify({
      purpose: "Academic credential state-update test",
      credentialModel: "ERC1155",
      protocol: "Nitrolite",
      testType: "operate-state-smoke-test",
    });

    console.log("Session data prepared.");
    console.log("");

    // ----------------------------------------------------------
    // 7. Sign application-session creation request
    // ----------------------------------------------------------

    const createPayload = packCreateAppSessionRequestV1(
      definition,
      sessionData,
    );

    const appSigner1 = new AppSessionWalletSignerV1(
      new EthereumMsgSigner(PK1),
    );

    const appSigner2 = new AppSessionWalletSignerV1(
      new EthereumMsgSigner(PK2),
    );

    console.log("Signing application-session creation request...");

    const createSignature1 =
      await appSigner1.signMessage(createPayload);

    const createSignature2 =
      await appSigner2.signMessage(createPayload);

    console.log("Both creation signatures generated.");
    console.log("");

    // ----------------------------------------------------------
    // 8. Create the app session
    // ----------------------------------------------------------

    console.log("Creating application session...");

    const session = await client1.createAppSession(
      definition,
      sessionData,
      [
        createSignature1,
        createSignature2,
      ],
    );

    console.log("");
    console.log("Application session created.");
    console.log("App Session ID:", session.appSessionId);
    console.log("Initial version:", session.version);
    console.log("Status:", session.status);
    console.log("");

    // ----------------------------------------------------------
    // 9. Build version 2 OPERATE state
    //
    // The newly created app session starts at version 1.
    // Therefore the first state update must be version 2.
    //
    // Zero allocations are deliberately used for this first
    // smoke test. We are testing the state-update mechanism,
    // not deposits.
    // ----------------------------------------------------------

    const appStateUpdate: AppStateUpdateV1 = {
      appSessionId: session.appSessionId,

      intent: AppStateUpdateIntent.Operate,

      version: 2n,

      allocations: [],

      sessionData: JSON.stringify({
        purpose: "Academic credential state-update test",
        credentialModel: "ERC1155",

        state: {
          action: "credential_batch_commitment",
          batchId: "test-batch-001",
          credentialCount: 0,
        },
      }),
    };

    console.log("Application state prepared.");
    console.log("Intent: OPERATE");
    console.log("Version:", appStateUpdate.version.toString());
    console.log("Allocations:", appStateUpdate.allocations.length);
    console.log("");

    // ----------------------------------------------------------
    // 10. Create deterministic signing payload
    // ----------------------------------------------------------

    const statePayload =
      packAppStateUpdateV1(appStateUpdate);

    console.log("State signing payload:");
    console.log(statePayload);
    console.log("");

    // ----------------------------------------------------------
    // 11. Both participants sign the state update
    // ----------------------------------------------------------

    console.log("Signing application state update...");

    const stateSignature1 =
      await appSigner1.signMessage(statePayload);

    const stateSignature2 =
      await appSigner2.signMessage(statePayload);

    console.log("Participant 1 state signature created.");
    console.log("Participant 2 state signature created.");
    console.log("");

    // ----------------------------------------------------------
    // 12. Submit state to Nitronode
    // ----------------------------------------------------------

    console.log("Submitting application state to Nitronode...");

    await client1.submitAppState(
      appStateUpdate,
      [
        stateSignature1,
        stateSignature2,
      ],
    );

    // ----------------------------------------------------------
    // 13. Success
    // ----------------------------------------------------------

    console.log("");
    console.log("==============================================");
    console.log(" APPLICATION STATE SUBMITTED SUCCESSFULLY");
    console.log("==============================================");
    console.log("App Session ID:", session.appSessionId);
    console.log("Submitted version:", appStateUpdate.version.toString());
    console.log("Intent: OPERATE");
    console.log("Quorum signatures: 2");
    console.log("==============================================");
    console.log("");

  } finally {
    // ----------------------------------------------------------
    // 14. Close connections
    // ----------------------------------------------------------

    console.log("Closing participant 1 connection...");
    await client1.close();

    console.log("Closing participant 2 connection...");
    await client2.close();

    console.log("Both Nitronode connections closed.");
  }
}

main().catch((error: unknown) => {
  console.error("");
  console.error("==============================================");
  console.error(" APP STATE TEST FAILED");
  console.error("==============================================");

  if (error instanceof Error) {
    console.error("Error:", error.message);
    console.error("");
    console.error(error.stack);
  } else {
    console.error(error);
  }

  process.exit(1);
});
