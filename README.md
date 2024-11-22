# Lisk node

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
![GitHub repo size](https://img.shields.io/github/repo-size/liskhq/lisk-node)
![GitHub issues](https://img.shields.io/github/issues-raw/liskhq/lisk-node)
![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/liskhq/lisk-node)

Lisk provides a cost-efficient, fast, and scalable Layer 2 (L2) network based on [Optimism (OP)](https://stack.optimism.io/) that is secured by Ethereum.

This repository contains information on how to run your own node on the Lisk network.

## System requirements

We recommend you the following hardware configuration to run a Lisk L2 node:

- a modern multi-core CPU with good single-core performance
- a minimum of 16 GB RAM (32 GB recommended)
- a locally attached NVMe SSD drive
- adequate storage capacity to accommodate both the snapshot restoration process (if restoring from snapshot) and chain data, ensuring a minimum of (2 \* current_chain_size) + snapshot_size + 20%\_buffer
- if running with docker, please install Docker Engine version [27.0.1](https://docs.docker.com/engine/release-notes/27.0/) or higher

**Note:** If utilizing Amazon Elastic Block Store (EBS), ensure timing buffered disk reads are fast enough in order to avoid latency issues alongside the rate of new blocks added to Base during the initial synchronization process; `io2 block express` is recommended.

## Supported networks

| Network      | Status |
| ------------ | ------ |
| Lisk Sepolia | ✅     |
| Lisk Mainnet | ✅     |

## Usage

> **Note**:
> - It is now possible to run the Lisk nodes with the `--op-network` flag on the op-geth execution client.
> - It is still not possible to run the Lisk nodes with the `--chain` flag on the op-reth execution client.

### Clone the Repository

```sh
git clone https://github.com/LiskHQ/lisk-node.git
cd lisk-node
```

### Docker

1. Ensure you have an Ethereum L1 full node RPC available (not Lisk), and set the `OP_NODE_L1_ETH_RPC` and the `OP_NODE_L1_BEACON` variables (within the `.env.*` files, if using docker-compose). If running your own L1 node, it needs to be synced before the Lisk node will be able to fully sync.

1. Please ensure that the environment file relevant to your network (`.env.sepolia`, or `.env.mainnet`) is set for the `env_file` properties at two places within `docker-compose.yml`. By default, it is set to `.env.mainnet`.

1. We currently support running either the `op-geth` or the `op-reth` nodes alongside the `op-node`. By default, we run the `op-geth` node. If you would like to run the `op-reth` client, please set the `CLIENT` environment variable to `reth` before starting the node.
    > **Note**:
    > - The `op-reth` client can be built in either the `maxperf` (default) or `release` profile. To learn more about them, please check reth's documentation on [Optimizations](https://github.com/paradigmxyz/reth/blob/main/book/installation/source.md#optimizations). Please set the `RETH_BUILD_PROFILE` environment variable accordingly.
    > - Unless you are building the `op-reth` client in `release` profile, please ensure that you have a machine with 32 GB RAM.
    > - Additionally, if you have the Docker Desktop installed on your system, please make sure to set `Memory limit` to a minimum of `16 GB`.<br>It can be set under `Settings -> Resources -> Resource Allocation -> Memory limit`.

1. Run:
    <br>**IMPORTANT**: To run the node on Lisk Sepolia, first patch the Dockerfile(s) with:
    ```sh
    git apply dockerfile-lisk-sepolia.patch
    ```

    <br>with `op-geth` execution client:
    ```sh
    docker compose up --build --detach
    ```
    or, with `op-reth` execution client:
    ```sh
    CLIENT=reth RETH_BUILD_PROFILE=maxperf docker compose up --build --detach
    ```

1. You should now be able to `curl` your Lisk node:
    ```sh
    curl -s -d '{"id":0,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
      -H "Content-Type: application/json" http://localhost:8545
    ```

### Source

#### Build

- Before proceeding, please make sure to install the following dependency (**this information is missing in the OP documentations linked below**):
  - [jq](https://jqlang.github.io/jq/)

- To build `op-node` and `op-geth` from source, follow OP documentation on [Building a Node from Source](https://docs.optimism.io/builders/node-operators/tutorials/node-from-source).
  - Before building the `op-node`, please patch the code with [`op-node-lisk-sepolia.patch`](./op-node-lisk-sepolia.patch) for an unhandled `SystemConfig` event emitted on Lisk Sepolia, resulting in errors on the Lisk nodes.
    ```sh
    git apply <path-to-op-node-lisk-sepolia.patch>
    ```

- To build `op-reth` from source, follow the reth official [documentation](https://reth.rs/run/optimism.html#installing-op-reth).

#### Set environment variables

Set the following environment variable:

```
export DATADIR_PATH=... # Path to the folder where geth data will be stored
```

#### Create a JWT Secret

`op-geth` and `op-node` communicate over the engine API authrpc. This communication can be secured with a shared secret which can be provided to both when starting the applications. In this case, the secret takes the form of a random 32-byte hex string and can be generated with:

```
openssl rand -hex 32 > jwt.txt
```

For more information refer to the OP [documentation](https://docs.optimism.io/builders/node-operators/tutorials/mainnet#create-a-jwt-secret).

#### Initialize op-geth

> **Important**: If you already had your node running prior to the Fjord upgrade (Sepolia: May 29, 2024 & Mainnet: July 10, 2024), please make sure to re-initialize your data directory with the updated genesis block. This is automatically taken care of for the Docker users.

Navigate to your `op-geth` directory and initialize the service by running the command:

```sh
./build/bin/geth init --datadir=$DATADIR_PATH PATH_TO_NETWORK_GENESIS_FILE
```

> **Note**:
> - Alternatively, this initialization step can be skipped by specifying `--op-network=OP_NODE_NETWORK` flag in the start commands below.
> - This flag automatically fetches the necessary information from the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry).

#### Run op-geth

Navigate to your `op-geth` directory and start service by running the command:

```sh
./build/bin/geth \
    --op-network=$OP_NODE_NETWORK \
    --datadir=$DATADIR_PATH \
    --verbosity=3 \
    --authrpc.addr=0.0.0.0 \
    --authrpc.port=8551 \
    --authrpc.vhosts="*" \
    --authrpc.jwtsecret=PATH_TO_JWT_TEXT_FILE \
    --ws \
    --ws.addr=0.0.0.0 \
    --ws.port=8546 \
    --ws.origins="*" \
    --ws.api=debug,eth,net,engine \
    --http \
    --http.corsdomain="*" \
    --http.vhosts="*" \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.api=web3,debug,eth,net,engine \
    --metrics \
    --metrics.addr=0.0.0.0 \
    --metrics.port=6060 \
    --syncmode=full \
    --gcmode=full \
    --port=30303 \
    --maxpeers=100 \
    --rollup.sequencerhttp=SEQUENCER_HTTP \
    --rollup.halt=major \
    --rollup.disabletxpoolgossip=true \
    --nat=extip:0.0.0.0
```

Refer to the `op-geth` configuration [documentation](https://docs.optimism.io/builders/node-operators/management/configuration#op-geth) for detailed information about available options.

#### Run op-reth

Navigate to your `reth` directory and start service by running the command:

```sh
./target/release/op-reth node \
  -vvv \
  --chain=PATH_TO_NETWORK_GENESIS_FILE \
  --datadir="$DATADIR_PATH" \
  --log.stdout.format log-fmt \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=PATH_TO_JWT_TEXT_FILE \
  --ws \
  --ws.origins="*" \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.api=debug,eth,net,txpool \
  --http \
  --http.corsdomain="*" \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=web3,debug,eth,net,txpool \
  --metrics=0.0.0.0:6060 \
  --disable-discovery \
  --port=30303 \
  --rollup.sequencer-http=SEQUENCER_HTTP \
  --rollup.disable-tx-pool-gossip
```

Refer to the `reth` configuration [documentation](https://reth.rs/cli/reth/node.html#reth-node) for detailed information about available options.

> **Note**:
> <br>Official Lisk Sequencer HTTP RPC:
> - **Lisk Sepolia**: https://rpc.sepolia-api.lisk.com
> - **Lisk Mainnet**: https://rpc.api.lisk.com

#### Run op-node

Navigate to your `op-node` directory and start service by running the command:

```sh
./bin/op-node \
  --network="$OP_NODE_NETWORK" \
  --l1=$OP_NODE_L1_ETH_RPC \
  --l1.rpckind=$OP_NODE_L1_RPC_KIND \
  --l1.beacon=$OP_NODE_L1_BEACON \
  --l2=ws://localhost:8551 \
  --l2.jwt-secret=PATH_TO_JWT_TEXT_FILE
```

The above command starts `op-node` in **full sync** mode. Depending on the chain length, the initial sync process could take significant time; varying from days to weeks.

```
INFO [06-26|13:31:20.389] Advancing bq origin                      origin=17171d..1bc69b:8300332 originBehind=false
```

For more information refer to the OP [documentation](https://docs.optimism.io/builders/node-operators/tutorials/mainnet#full-sync).

> **Note**:
> - In case you had skipped the `op-geth` [initialization step](#initialize-op-geth) above, you can start the node with the `--network=OP_NODE_NETWORK` flag.
> - When specifying the `--network` flag, kindly make sure to remove the `--rollup.config` flag.

Refer to the `op-node` configuration [documentation](https://docs.optimism.io/builders/node-operators/management/configuration#op-node) for detailed information about available options.

> **Note**:
> <br>Some L1 nodes (e.g. Erigon) do not support fetching storage proofs. You can work around this by specifying `--l1.trustrpc` when starting op-node (add it in `op-node-entrypoint` and rebuild the docker image with `docker compose build`.) Do not do this unless you fully trust the L1 node provider.

## Snapshots

> **Note**:
> - Snapshots are only available for the `op-geth` client and are from an archival node. They are of two types:
>   - `export`: small download size, slow to restore from, data is verified during restore
>   - `datadir`: large download size, fast to restore from, no data verification during restore

### Docker

To enable auto-snapshot download and application, please set the `APPLY_SNAPSHOT` environment variable to `true`, when starting the node.
```sh
APPLY_SNAPSHOT=true docker compose up --build --detach
```

To choose the snapshot type, please set the `SNAPSHOT_TYPE` flag to either `export` (default) or `datadir`, when starting the node.
```sh
APPLY_SNAPSHOT=true SNAPSHOT_TYPE=export docker compose up --build --detach
```

You can also download and apply a snapshot from a custom URL by setting the `SNAPSHOT_URL` environment variable.
Please make sure the snapshot file ends with `*.tar.gz`.
```sh
APPLY_SNAPSHOT=true SNAPSHOT_URL=<custom-snapshot-url> docker compose up --build --detach
```

### Source

Please follow the steps below:

- Download the snapshot and the corresponding checksum from. The latest snapshot name is always listed in the `latest-<export|datadir>` file:
  - Sepolia: https://snapshots.lisk.com/sepolia
  - Mainnet: https://snapshots.lisk.com/mainnet

- Verify the integrity of the downloaded snapshot with:
  ```sh
  sha256sum -c <checksum-file-name>
  ```

- Import the snapshot:
  - `export`:
    ```sh
    tar -xf <path-to-downloaded-export-snapshot-tarball>
    ./build/bin/geth import --datadir=$GETH_DATA_DIR <path-to-extracted-export-snapshot>
    ```
  - `datadir`:
    ```sh
    tar --directory $GETH_DATA_DIR -xf <path-to-datadir-snapshot>
    ```

## Syncing

Sync speed depends on your L1 node, as the majority of the chain is derived from data submitted to the L1. You can check your syncing status using the `optimism_syncStatus` RPC on the `op-node` container. Example:

```
command -v jq  &> /dev/null || { echo "jq is not installed" 1>&2 ; }
echo Latest synced block behind by: \
$((($( date +%s )-\
$( curl -s -d '{"id":0,"jsonrpc":"2.0","method":"optimism_syncStatus"}' -H "Content-Type: application/json" http://localhost:9545 |
   jq -r .result.unsafe_l2.timestamp))/60)) minutes
```
