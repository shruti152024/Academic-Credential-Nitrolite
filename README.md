# Layer-2 Enabled Multi-Token NFT Framework for Academic Credential Management

## Overview

This repository contains the implementation developed for the research paper:

**"A Scalable Layer-2 Enabled Multi-Token NFT Framework for Academic Credential Management"**

The proposed framework integrates:

- Nitrolite Layer-2 State Channels
- ERC-721 Soulbound Tokens
- ERC-1155 Academic Credential Tokens
- ERC-20 Academic Credit Tokens
- IPFS-based decentralized storage
- Merkle Tree verification

The objective is to provide a scalable, secure, tamper-resistant, and gas-efficient academic credential management system.

---

# Repository Structure

```
Academic-Credential-Nitrolite/
│
├── src/                  Solidity smart contracts
├── script/               Deployment and benchmarking scripts
├── dataset/              Synthetic academic datasets
├── lib/                  Foundry libraries
├── foundry.toml
├── foundry.lock
├── .gitignore
└── README.md
```

---

# Smart Contracts

The implementation includes:

- AcademicCredentialManager.sol
- AcademicCredit.sol
- CourseAchievement.sol
- DegreeSBT.sol
- NitroliteCredentialManager.sol
- ChannelHub.sol
- ChannelEngine.sol
- MerkleVerifier.sol
- PermitERC20.sol
- EscrowDepositEngine.sol
- EscrowWithdrawalEngine.sol

Supporting modules:

- interfaces/
- sigValidators/
- Utils.sol
- WadMath.sol

---

# Experimental Evaluation

The framework was evaluated using:

- Certificate Minting Latency
- Transaction Throughput
- Gas Consumption
- Nitrolite Layer-2 Gas Consumption
- IPFS Upload Time
- IPFS Retrieval Time
- Credential Verification Latency

Experiments were performed using Foundry and Anvil with synthetic datasets containing 100, 250, 500, 750, and 1000 academic records.

---

# Dataset

The `dataset` directory contains:

- generator.js
- students_100.json
- students_250.json
- students_500.json
- students_750.json
- students_1000.json

---
## Install Dependencies

After cloning the repository, install the required Foundry libraries:

```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
```

# Build

```bash
forge build
```

# Test

```bash
forge test
```

# Run Local Blockchain

```bash
anvil
```

---

# License

This repository is released under the MIT License.

---

# Citation

If you use this repository in academic work, please cite the associated publication.