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

// First benchmark: 50 logical academic credentials
const TOTAL_CREDENTIALS = 1000;

if (!PK1) {
  throw new Error("TEST_PRIVATE_KEY is missing from .env");
}

if (!PK2) {
  throw new Error("TEST_PRIVATE_KEY_2 is missing from .env");
}

async function main() {
  console.log("==============================================");
  console.log("Nitrolite Academic Credential Benchmark");
  console.log("==============================================");

  console.log(
    "Total logical credentials:",
    TOTAL_CREDENTIALS
  );

  // ----------------------------------------------------
  // CONNECT TWO PARTICIPANTS
  // ----------------------------------------------------

  console.log("\nConnecting participants...");

  const signer1 = createSigners(PK1);
  const signer2 = createSigners(PK2);

  const client1 = await Client.create(
    WS_URL,
    signer1.stateSigner,
    signer1.txSigner
  );

  const client2 = await Client.create(
    WS_URL,
    signer2.stateSigner,
    signer2.txSigner
  );

  try {
    const address1 = client1.getUserAddress();
    const address2 = client2.getUserAddress();

    console.log("Participant 1:", address1);
    console.log("Participant 2:", address2);

    // ----------------------------------------------------
    // APPLICATION DEFINITION
    // ----------------------------------------------------

    const applicationId =
      `academic-credential-benchmark-${Date.now().toString(36)}`;

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

    const sessionData = JSON.stringify({
      application: "Academic Credential Management",
      credentialStandard: "ERC-1155",
      protocol: "Nitrolite",
      experiment: "Off-chain application-state benchmark",
    });

    console.log("\nApplication ID:", applicationId);
    console.log(
      "Participants:",
      definition.participants.length
    );
    console.log("Quorum:", definition.quorum);

    // ----------------------------------------------------
    // APPLICATION SIGNERS
    // ----------------------------------------------------

    const appSigner1 =
      new AppSessionWalletSignerV1(
        new EthereumMsgSigner(PK1)
      );

    const appSigner2 =
      new AppSessionWalletSignerV1(
        new EthereumMsgSigner(PK2)
      );

    // ----------------------------------------------------
    // CREATE APPLICATION SESSION
    // ----------------------------------------------------

    console.log("\nCreating application session...");

    const createPayload =
      packCreateAppSessionRequestV1(
        definition,
        sessionData
      );

    const signature1 =
      await appSigner1.signMessage(createPayload);

    const signature2 =
      await appSigner2.signMessage(createPayload);

    const sessionResult =
      await client1.createAppSession(
        definition,
        sessionData,
        [
          signature1,
          signature2,
        ]
      );

    const appSessionId =
      sessionResult.appSessionId;

    console.log(
      "Application session created successfully."
    );

    console.log(
      "App Session ID:",
      appSessionId
    );

    console.log(
      "Initial version:",
      sessionResult.version
    );

    console.log(
      "Status:",
      sessionResult.status
    );

    // ----------------------------------------------------
    // BENCHMARK VARIABLES
    // ----------------------------------------------------

    const submissionTimes: number[] = [];

    let successfulUpdates = 0;
    let failedUpdates = 0;

    const benchmarkStart =
      performance.now();

    // ----------------------------------------------------
    // SUBMIT CREDENTIAL STATES
    // ----------------------------------------------------
    //
    // Session creation = version 1
    //
    // Credential 1 = version 2
    // Credential 2 = version 3
    // ...
    // Credential 50 = version 51
    //
    // These OPERATE states are submitted to Nitronode.
    // They are not individual blockchain transactions.
    // ----------------------------------------------------

    for (
      let studentIndex = 1;
      studentIndex <= TOTAL_CREDENTIALS;
      studentIndex++
    ) {
      const version =
        BigInt(studentIndex + 1);

      const credential = {
        studentIndex: studentIndex,
        courseId: 101,
        credentialType: "ERC-1155",
        ipfsCID:
          `ipfs://academic-course-${studentIndex}`,
      };

      const appState: AppStateUpdateV1 = {
        appSessionId: appSessionId,

        version: version,

        intent:
          AppStateUpdateIntent.Operate,

        allocations: [],

        sessionData:
          JSON.stringify(credential),
      };

      // Pack state for signing
      const statePayload =
        packAppStateUpdateV1(appState);

      // Participant 1 signs
      const stateSignature1 =
        await appSigner1.signMessage(
          statePayload
        );

      // Participant 2 signs
      const stateSignature2 =
        await appSigner2.signMessage(
          statePayload
        );

      // Measure Nitronode submission time
      const start =
        performance.now();

      try {
        await client1.submitAppState(
          appState,
          [
            stateSignature1,
            stateSignature2,
          ]
        );

        const end =
          performance.now();

        const elapsed =
          end - start;

        submissionTimes.push(elapsed);

        successfulUpdates++;

        console.log(
          `Credential ${studentIndex}/${TOTAL_CREDENTIALS} | ` +
          `version=${version.toString()} | ` +
          `${elapsed.toFixed(3)} ms`
        );

      } catch (error) {
        failedUpdates++;

        console.error(
          `Credential ${studentIndex} FAILED`
        );

        console.error(error);

        throw error;
      }
    }

    const benchmarkEnd =
      performance.now();

    const totalBenchmarkTime =
      benchmarkEnd - benchmarkStart;

    // ----------------------------------------------------
    // STATISTICS
    // ----------------------------------------------------

    const sum =
      submissionTimes.reduce(
        (a, b) => a + b,
        0
      );

    const mean =
      submissionTimes.length > 0
        ? sum / submissionTimes.length
        : 0;

    const minimum =
      submissionTimes.length > 0
        ? Math.min(...submissionTimes)
        : 0;

    const maximum =
      submissionTimes.length > 0
        ? Math.max(...submissionTimes)
        : 0;

    const sorted =
      [...submissionTimes].sort(
        (a, b) => a - b
      );

    // Median
    let median = 0;

    if (sorted.length > 0) {
      const middle =
        Math.floor(sorted.length / 2);

      if (sorted.length % 2 === 0) {
        const lower =
          sorted[middle - 1] ?? 0;

        const upper =
          sorted[middle] ?? 0;

        median =
          (lower + upper) / 2;
      } else {
        median =
          sorted[middle] ?? 0;
      }
    }

    // Standard deviation
    const variance =
      submissionTimes.length > 0
        ? submissionTimes.reduce(
            (acc, value) =>
              acc +
              Math.pow(
                value - mean,
                2
              ),
            0
          ) / submissionTimes.length
        : 0;

    const standardDeviation =
      Math.sqrt(variance);

    // Application-state throughput
    const throughput =
      totalBenchmarkTime > 0
        ? successfulUpdates /
          (totalBenchmarkTime / 1000)
        : 0;

    // ----------------------------------------------------
    // FINAL RESULTS
    // ----------------------------------------------------

    console.log("\n==============================================");
    console.log("BENCHMARK COMPLETE");
    console.log("==============================================");

    console.log(
      "Total credentials:",
      TOTAL_CREDENTIALS
    );

    console.log(
      "Successful updates:",
      successfulUpdates
    );

    console.log(
      "Failed updates:",
      failedUpdates
    );

    console.log(
      "Total benchmark time:",
      totalBenchmarkTime.toFixed(3),
      "ms"
    );

    console.log(
      "Mean submission time:",
      mean.toFixed(3),
      "ms"
    );

    console.log(
      "Median submission time:",
      median.toFixed(3),
      "ms"
    );

    console.log(
      "Minimum submission time:",
      minimum.toFixed(3),
      "ms"
    );

    console.log(
      "Maximum submission time:",
      maximum.toFixed(3),
      "ms"
    );

    console.log(
      "Standard deviation:",
      standardDeviation.toFixed(3),
      "ms"
    );

    console.log(
      "Application-state throughput:",
      throughput.toFixed(3),
      "updates/sec"
    );

    console.log(
      "\nBlockchain transactions generated",
      "for these OPERATE state submissions: 0"
    );

    console.log(
      "\n=============================================="
    );
    console.log(
      "Nitrolite off-chain benchmark finished."
    );
    console.log(
      "=============================================="
    );

  } finally {
    await client1.close();
    await client2.close();

    console.log(
      "\nBoth Nitronode connections closed."
    );
  }
}

main().catch((error) => {
  console.error("\nFAILED:");
  console.error(error);

  process.exit(1);
});