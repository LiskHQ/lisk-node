# Lisk node

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
![GitHub repo size](https://img.shields.io/github/repo-size/liskhq/lisk-node)
![GitHub issues](https://img.shields.io/github/issues-raw/liskhq/lisk-node)
![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/liskhq/lisk-node)

Lisk provides a cost-efficient, fast, and scalable Layer 2 (L2) network based on [Optimism (OP)](https://stack.optimism.io/) that is secured by Ethereum.

This repository contains information on how to run your own node on the Lisk network.

## System requirements

The following system requirements are recommended to run Lisk L2 node.

### Memory

- Modern multi-core CPU with good single-core performance
- Machines with a minimum of 16 GB RAM (32 GB recommended)

### Storage

- Machines with a high performance SSD drive with at least 4 TB free

## Supported networks

| Network              | Status |
| -------------------- | ------ |
| Lisk Sepolia Testnet | ✅     |
| Lisk Mainnet         | ✅     |

## Usage

> **Note**:
> <br>It is currently not possible to run the node until the configs for Lisk have been merged to the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry).
> <br>We currently have an [open PR](https://github.com/ethereum-optimism/superchain-registry/pull/234) to add the Lisk Mainnet config. We will soon create a PR to add the config for the Lisk Sepolia Testnet as well.

### Clone the Repository

```sh
git clone https://github.com/LiskHQ/lisk-node.git
cd lisk-node
```

### Docker

1. Ensure you have an Ethereum L1 full node RPC available (not Lisk), and set `OP_NODE_L1_ETH_RPC` (in the `.env.*` file if using docker-compose). If running your own L1 node, it needs to be synced before Lisk will be able to fully sync.
2. Uncomment the line relevant to your network (`.env.sepolia`, or `.env.mainnet`) under the 2 `env_file` keys in `docker-compose.yml`.
3. Run:

```
docker compose up --build
```

4. You should now be able to `curl` your Lisk node:

```
curl -d '{"id":0,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
  -H "Content-Type: application/json" http://localhost:8545
```

### Source

#### Build

To build `op-node` and `op-geth` from source, follow the OP [documentation](https://docs.optimism.io/builders/node-operators/tutorials/node-from-source).

#### Set environment variables

Set the following environment variable:

```
export DATADIR_PATH=... # Path to the folder where geth data will be stored
```

#### Create a JWT Secret

Run the following command to generate a random 32 byte hex string:

```
openssl rand -hex 32 > jwt.txt
```

For more information refer to the OP [documentation](https://docs.optimism.io/builders/node-operators/tutorials/mainnet#create-a-jwt-secret).

#### Initialize op-geth

Navigate to your `op-geth` directory and init service by running the command:

```sh
./build/bin/geth init --datadir=$DATADIR_PATH PATH_TO_NETWORK_GENESIS_FILE
```

> **Note**:
> <br>Alternatively, the above step can be skipped by specifying `--op-network=OP_NODE_NETWORK` flag in the start commands below.
> <br>The flags fetches information from the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry).

#### Run

Navigate to your `op-geth` directory and start service by running the command:

For, Lisk Sepolia Testnet:

```sh
./build/bin/geth \
    --datadir=$DATADIR_PATH \
    --verbosity=3 \
    --http \
    --http.corsdomain="*" \
    --http.vhosts="*" \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.api=web3,debug,eth,net,engine \
    --authrpc.addr=0.0.0.0 \
    --authrpc.port=8551 \
    --authrpc.vhosts="*" \
    --authrpc.jwtsecret=./jwt.txt \
    --ws \
    --ws.addr=0.0.0.0 \
    --ws.port=8546 \
    --ws.origins="*" \
    --ws.api=debug,eth,net,engine \
    --metrics \
    --metrics.addr=0.0.0.0 \
    --metrics.port=606 \
    --syncmode=full \
    --gcmode=full \
    --maxpeers=100 \
    --nat=extip:0.0.0.0 \
    --rollup.sequencerhttp=https://rpc.sepolia-api.lisk.com \
    --rollup.halt=major \
    --port=30303 \
    --rollup.disabletxpoolgossip=true \
    --override.canyon=0
```

For, Lisk Mainnet:

```sh
./build/bin/geth \
    --datadir=$DATADIR_PATH \
    --verbosity=3 \
    --http \
    --http.corsdomain="*" \
    --http.vhosts="*" \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.api=web3,debug,eth,net,engine \
    --authrpc.addr=0.0.0.0 \
    --authrpc.port=8551 \
    --authrpc.vhosts="*" \
    --authrpc.jwtsecret=./jwt.txt \
    --ws \
    --ws.addr=0.0.0.0 \
    --ws.port=8546 \
    --ws.origins="*" \
    --ws.api=debug,eth,net,engine \
    --metrics \
    --metrics.addr=0.0.0.0 \
    --metrics.port=606 \
    --syncmode=full \
    --gcmode=full \
    --maxpeers=100 \
    --nat=extip:0.0.0.0 \
    --rollup.sequencerhttp=https://rpc.api.lisk.com \
    --rollup.halt=major \
    --port=30303 \
    --rollup.disabletxpoolgossip=true
```

Refer to the `op-geth` configuration [documentation](https://docs.optimism.io/builders/node-operators/management/configuration#op-geth) for detailed information about available options.

Navigate to your `op-node` directory and start service by running the command:

For, Lisk Sepolia Testnet:

```sh
./bin/op-node \
  --l1=$L1_RPC_URL \
  --l1.rpckind=$L1_RPC_KIND \
  --l1.beacon=$L1_BEACON_URL \
  --l2=ws://localhost:8551 \
  --l2.jwt-secret=./jwt.txt \
  --rollup.config=PATH_TO_NETWORK_ROLLUP_FILE
```

For, Lisk Mainnet:

```sh
./bin/op-node \
  --l1=$L1_RPC_URL \
  --l1.rpckind=$L1_RPC_KIND \
  --l1.beacon=$L1_BEACON_URL \
  --l2=ws://localhost:8551 \
  --l2.jwt-secret=./jwt.txt \
  --rollup.config=PATH_TO_NETWORK_ROLLUP_FILE
```

After start, op-node is requesting blocks from Ethereum one-by-one and determining the corresponding OP Mainnet blocks that were published to Ethereum. You should see logs like the following from op-node:

```
INFO [06-26|13:31:20.389] Advancing bq origin                      origin=17171d..1bc69b:8300332 originBehind=false
```

For more information refer to the OP [documentation](https://docs.optimism.io/builders/node-operators/tutorials/mainnet#full-sync).

> **Note**:
> <br>In case you skipped the step to initialize `op-geth` service mentioned above, you can start the node by adding`--network=OP_NODE_NETWORK` flag.
> <br>Please ensure that `--rollup.config` is removed in case of `--network` flag.

Refer to the `op-node` configuration [documentation](https://docs.optimism.io/builders/node-operators/management/configuration#op-node) for detailed information about available options.

Note: Some L1 nodes (e.g. Erigon) do not support fetching storage proofs. You can work around this by specifying `--l1.trustrpc` when starting op-node (add it in `op-node-entrypoint` and rebuild the docker image with `docker compose build`.) Do not do this unless you fully trust the L1 node provider.

## Snapshots

TBA

### Syncing

Sync speed depends on your L1 node, as the majority of the chain is derived from data submitted to the L1. You can check your syncing status using the `optimism_syncStatus` RPC on the `op-node` container. Example:

```
command -v jq  &> /dev/null || { echo "jq is not installed" 1>&2 ; }
echo Latest synced block behind by: \
$((($( date +%s )-\
$( curl -s -d '{"id":0,"jsonrpc":"2.0","method":"optimism_syncStatus"}' -H "Content-Type: application/json" http://localhost:7545 |
   jq -r .result.unsafe_l2.timestamp))/60)) minutes
```
