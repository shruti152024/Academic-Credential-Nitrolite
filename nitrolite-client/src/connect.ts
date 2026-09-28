import "dotenv/config";

import {
  Client,
  createSigners,
  withErrorHandler,
} from "@yellow-org/sdk";

const wsURL =
  process.env.NITRONODE_WS_URL ??
  "wss://nitronode-sandbox.yellow.org/v1/ws";

const privateKey = process.env.TEST_PRIVATE_KEY as `0x${string}`;

if (!privateKey) {
  throw new Error("TEST_PRIVATE_KEY is missing from .env");
}

async function main() {
  console.log("Connecting to Nitronode...");
  console.log("URL:", wsURL);

  const { stateSigner, txSigner } = createSigners(privateKey);

  const client = await Client.create(
    wsURL,
    stateSigner,
    txSigner,
    withErrorHandler((error) => {
      console.error("Nitronode error:", error);
    }),
  );

  try {
    console.log("Connected successfully.");
    console.log("User address:", client.getUserAddress());

    const config = await client.getConfig();

    console.log("Nitronode configuration:");
    console.log(config);
  } finally {
    await client.close();
    console.log("Connection closed.");
  }
}

main().catch((error) => {
  console.error("FAILED:", error);
  process.exit(1);
});
