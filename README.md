# Lisk

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
![GitHub repo size](https://img.shields.io/github/repo-size/liskhq/lisk-node)
![GitHub issues](https://img.shields.io/github/issues-raw/liskhq/lisk-node)
![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/liskhq/lisk-node)

Lisk provides a cost-efficient, fast, and scalable Layer 2 (L2) network based on [Optimism (OP)](https://stack.optimism.io/). that is secured by Ethereum.

This repository contains information on how to run your own L2 node on the Lisk network.

## System requirements

The following system requirements are recommended to run Lisk l2 node.

### Memory

- Modern multi-core CPU with good single-core performance
- Machines with a minimum of 16 GB RAM (32 GB recommended).

### Storage

- Machines with a high performance SSD drive with at least 4 TB free

## Supported networks

| Ethereum Network | Status |
| ---------------- | ------ |
| Lisk             | ✅     |
| Lisk Sepolia     | ✅     |

## Usage

> **Note**:
> <br>It is currently not possible to run the node until the configs for Lisk have been merged to the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry).
> <br>We currently have an [open PR](https://github.com/ethereum-optimism/superchain-registry/pull/234) to add Lisk Mainnet config. We will soon create a PR to add the config for Lisk Sepolia Testnet as well.

### Clone the Repository

```sh
git clone https://github.com/LiskHQ/lisk-node.git
cd lisk-node
```

### Docker

- Ensure you have an Ethereum L1 full node RPC available (not Lisk), and copy `.env.*` (based on the network) to `.env` setting `OP_NODE_L1_ETH_RPC`. If running your own L1 node, it needs to be synced before the specific Lisk network will be able to fully sync. You also need a Beacon API RPC which can be set in `OP_NODE_L1_BEACON`. Example:

  ```
  # .env file
  # [recommended] replace with your preferred L1 (Ethereum, not Lisk) node RPC URL:
  OP_NODE_L1_ETH_RPC=<L1 api rpc>
  OP_NODE_L1_BEACON=<beacon api rpc>
  ```

- Start the node:

  ```
  docker compose up --build
  ```

- You should now be able to `curl` your Lisk node:

  ```
  curl -d '{"id":0,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8545
  ```

### Source

#### Build

To build `op-node` and `op-geth` from source, follow this optimism document [documentation](https://docs.optimism.io/builders/node-operators/tutorials/node-from-source)

#### Run

Navigate to your `op-geth` directory and start service by running the command:

For Lisk Sepolia Testnet:

```sh
./build/bin/geth \
  --http \
  --http.port=8545 \
  --http.addr=localhost \
  --authrpc.addr=localhost \
  --authrpc.jwtsecret=./jwt.txt \
  --verbosity=3 \
  --rollup.sequencerhttp=https://rpc.sepolia-api.lisk.com/ \
  --op-network=lisk-sepolia \
  --datadir=$DATADIR_PATH \
  --override.canyon=0
```

For Lisk Mainnet:

```sh
./build/bin/geth \
  --http \
  --http.port=8545 \
  --http.addr=localhost \
  --authrpc.addr=localhost \
  --authrpc.jwtsecret=./jwt.txt \
  --verbosity=3 \
  --rollup.sequencerhttp=https://rpc.api.lisk.com/ \
  --op-network=lisk \
  --datadir=$DATADIR_PATH
```

Refer to the `op-geth` configuration [documentation](https://docs.optimism.io/builders/node-operators/management/configuration#op-geth) for detailed information about available options.

Navigate to your `op-node` directory and start service by running the command:

For Lisk Sepolia Testnet:

```sh
./bin/op-node \
  --l1=$L1_RPC_URL \
  --l1.rpckind=$L1_RPC_KIND \
  --l1.beacon=$L1_BEACON_URL \
  --l2=ws://localhost:8551 \
  --l2.jwt-secret=./jwt.txt \
  --network=lisk-sepolia \
  --syncmode=execution-layer
```

For Lisk Mainnet:

```sh
./bin/op-node \
  --l1=$L1_RPC_URL \
  --l1.rpckind=$L1_RPC_KIND \
  --l1.beacon=$L1_BEACON_URL \
  --l2=ws://localhost:8551 \
  --l2.jwt-secret=./jwt.txt \
  --network=lisk \
  --syncmode=execution-layer
```

Refer to the `op-node` configuration [documentation](https://docs.optimism.io/builders/node-operators/management/configuration#op-node) for detailed information about available options.

Note: Some L1 nodes (e.g. Erigon) do not support fetching storage proofs. You can work around this by specifying `--l1.trustrpc` when starting op-node (add it in `op-node-entrypoint` and rebuild the docker image with `docker compose build`.) Do not do this unless you fully trust the L1 node provider.

## Snapshots

Not yet available.

### Syncing

Sync speed depends on your L1 node, as the majority of the chain is derived from data submitted to the L1. You can check your syncing status using the `optimism_syncStatus` RPC on the `op-node` container. Example:

```
command -v jq  &> /dev/null || { echo "jq is not installed" 1>&2 ; }
echo Latest synced block behind by: \
$((($( date +%s )-\
$( curl -s -d '{"id":0,"jsonrpc":"2.0","method":"optimism_syncStatus"}' -H "Content-Type: application/json" http://localhost:7545 |
   jq -r .result.unsafe_l2.timestamp))/60)) minutes
```

## Disclaimer

We’re excited for you to build on Base 🔵 — but we want to make sure that you understand the nature of the node software and smart contracts offered here.

THE NODE SOFTWARE AND SMART CONTRACTS CONTAINED HEREIN ARE FURNISHED AS IS, WHERE IS, WITH ALL FAULTS AND WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF MERCHANTABILITY, NON- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE. IN PARTICULAR, THERE IS NO REPRESENTATION OR WARRANTY THAT THE NODE SOFTWARE AND SMART CONTRACTS WILL PROTECT YOUR ASSETS — OR THE ASSETS OF THE USERS OF YOUR APPLICATION — FROM THEFT, HACKING, CYBER ATTACK, OR OTHER FORM OF LOSS OR DEVALUATION.

You also understand that using the node software and smart contracts are subject to applicable law, including without limitation, any applicable anti-money laundering laws, anti-terrorism laws, export control laws, end user restrictions, privacy laws, or economic sanctions laws/regulations.
