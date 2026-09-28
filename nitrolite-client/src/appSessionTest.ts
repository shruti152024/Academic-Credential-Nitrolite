import "dotenv/config";

import {
  Client,
  createSigners,
  AppSessionWalletSignerV1,
  EthereumMsgSigner,
  packCreateAppSessionRequestV1,
  type AppDefinitionV1,
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
  console.log(" Nitronode V1 App Session Smoke Test");
  console.log("==============================================");
  console.log("Nitronode URL:", WS_URL);
  console.log("");

  // ------------------------------------------------------------
  // 1. Create blockchain/state signers
  // ------------------------------------------------------------

  console.log("Creating participant signers...");

  const signer1 = createSigners(PK1);
  const signer2 = createSigners(PK2);

  // ------------------------------------------------------------
  // 2. Connect both participants to Nitronode
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
    // 3. Get participant wallet addresses
    // ----------------------------------------------------------

    const address1 = client1.getUserAddress();
    const address2 = client2.getUserAddress();

    console.log("Participant 1:", address1);
    console.log("Participant 2:", address2);
    console.log("");

    // ----------------------------------------------------------
    // 4. Create a unique application ID
    // ----------------------------------------------------------

    const applicationId =
      `academic-credential-test-${Date.now().toString(36)}`
        .toLowerCase();

    console.log("Application ID:", applicationId);
    console.log("");

    // ----------------------------------------------------------
    // 5. Define the Nitrolite application session
    //
    // Two participants
    // Weight of each participant = 1
    // Quorum = 2
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

      // Must be non-zero.
      nonce: BigInt(Date.now()),
    };

    console.log("Application definition created.");
    console.log("Participants:", definition.participants.length);
    console.log("Quorum:", definition.quorum);
    console.log("Nonce:", definition.nonce.toString());
    console.log("");

    // ----------------------------------------------------------
    // 6. Session metadata
    //
    // This is application/session data.
    // It is NOT an ERC-1155 transfer.
    // ----------------------------------------------------------

    const sessionData = JSON.stringify({
      purpose: "Academic credential settlement test",
      credentialModel: "ERC1155",
      protocol: "Nitrolite",
      testType: "two-participant-app-session",
    });

    console.log("Session data prepared.");
    console.log("");

    // ----------------------------------------------------------
    // 7. Create the exact hash required by Nitronode
    //
    // Current Nitronode V1 verifies:
    //
    // application
    // participants
    // quorum
    // nonce
    // sessionData
    //
    // using PackCreateAppSessionRequestV1.
    // ----------------------------------------------------------

    const createPayload = packCreateAppSessionRequestV1(
      definition,
      sessionData,
    );

    console.log("App-session signing payload created:");
    console.log(createPayload);
    console.log("");

    // ----------------------------------------------------------
    // 8. Create app-session wallet signers
    // ----------------------------------------------------------

    const appSigner1 = new AppSessionWalletSignerV1(
      new EthereumMsgSigner(PK1),
    );

    const appSigner2 = new AppSessionWalletSignerV1(
      new EthereumMsgSigner(PK2),
    );

    // ----------------------------------------------------------
    // 9. Both participants sign the SAME creation payload
    // ----------------------------------------------------------

    console.log("Signing app-session creation request...");

    const signature1 = await appSigner1.signMessage(createPayload);
    const signature2 = await appSigner2.signMessage(createPayload);

    console.log("Participant 1 signature created.");
    console.log("Participant 2 signature created.");
    console.log("");

    // ----------------------------------------------------------
    // 10. Create the application session
    //
    // IMPORTANT:
    // No registerApp() call is used.
    //
    // Current Nitronode V1 create_app_session validates:
    // - application ID
    // - participants
    // - quorum
    // - nonce
    // - participant signatures
    //
    // The new session starts with version 1
    // and zero allocations.
    // ----------------------------------------------------------

    console.log("Creating Nitronode application session...");

    const result = await client1.createAppSession(
      definition,
      sessionData,
      [
        signature1,
        signature2,
      ],
    );

    // ----------------------------------------------------------
    // 11. Display result
    // ----------------------------------------------------------

    console.log("");
    console.log("==============================================");
    console.log(" APPLICATION SESSION CREATED SUCCESSFULLY");
    console.log("==============================================");
    console.log("Application ID:", applicationId);
    console.log("App Session ID:", result.appSessionId);
    console.log("Version:", result.version);
    console.log("Status:", result.status);
    console.log("==============================================");
    console.log("");

  } finally {
    // ----------------------------------------------------------
    // 12. Close both Nitronode connections
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
  console.error(" APP SESSION TEST FAILED");
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