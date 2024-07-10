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

- Machines with a high performance SSD drive with at least 750GB (full node) or 4.5TB (archive node) free

## Supported networks

| Network              | Status |
| -------------------- | ------ |
| Lisk Sepolia Testnet | ✅     |
| Lisk Mainnet         | ✅     |

## Usage

> **Note**:
> <br>It is currently not possible to run the nodes with the `--op-network` flag until the configs for Lisk have been merged to the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry).
> <br>Currently, due to ongoing changes in the above repo, addition of new chains to the registry have been paused. Once the maintenance is over, we will submit PRs to add the config for the Lisk Mainnet and Lisk Sepolia Testnet.

### Clone the Repository

```sh
git clone https://github.com/LiskHQ/lisk-node.git
cd lisk-node
```

### Docker

1. Ensure you have an Ethereum L1 full node RPC available (not Lisk), and set the `OP_NODE_L1_ETH_RPC` and the `OP_NODE_L1_BEACON` variables (within the `.env.*` files, if using docker-compose). If running your own L1 node, it needs to be synced before the Lisk node will be able to fully sync.
2. Please ensure that the environment file relevant to your network (`.env.sepolia`, or `.env.mainnet`) is set for the `env_file` properties within `docker-compose.yml`. By default, it is set to `.env.mainnet`.
3. We currently support running either the `op-geth` or the `op-reth` nodes alongside the `op-node`. By default, we run the `op-geth` node. If you would like to run the `op-reth` node instead, please set the `CLIENT` environment variable to `reth` before starting the node.
4. Run:

```
docker compose up --build --detach
```

4. You should now be able to `curl` your Lisk node:

```
curl -s -d '{"id":0,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
  -H "Content-Type: application/json" http://localhost:8545
```

### Source

#### Build

To build `op-node` and `op-geth` from source, follow the OP [documentation](https://docs.optimism.io/builders/node-operators/tutorials/node-from-source).
<br>To build `op-reth` from source, follow the reth official [documentation](https://reth.rs/run/optimism.html#installing-op-reth).
<br>Before proceeding, please make sure to install the following dependency (**this information is missing in the above OP documentation**):

- jq

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

Navigate to your `op-geth` directory and initialize the service by running the command:

```sh
./build/bin/geth init --datadir=$DATADIR_PATH PATH_TO_NETWORK_GENESIS_FILE
```

> **Note**:
> <br>Alternatively, this initialization step can be skipped by specifying `--op-network=OP_NODE_NETWORK` flag in the start commands below.
> <br>This flag automatically fetches the necessary information from the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry).

#### Run op-geth

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
    --authrpc.jwtsecret=PATH_TO_JWT_TEXT_FILE \
    --ws \
    --ws.addr=0.0.0.0 \
    --ws.port=8546 \
    --ws.origins="*" \
    --ws.api=debug,eth,net,engine \
    --metrics \
    --metrics.addr=0.0.0.0 \
    --metrics.port=6060 \
    --syncmode=full \
    --gcmode=full \
    --maxpeers=100 \
    --nat=extip:0.0.0.0 \
    --rollup.sequencerhttp=SEQUENCER_HTTP \
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
    --authrpc.jwtsecret=PATH_TO_JWT_TEXT_FILE \
    --ws \
    --ws.addr=0.0.0.0 \
    --ws.port=8546 \
    --ws.origins="*" \
    --ws.api=debug,eth,net,engine \
    --metrics \
    --metrics.addr=0.0.0.0 \
    --metrics.port=6060 \
    --syncmode=full \
    --gcmode=full \
    --maxpeers=100 \
    --nat=extip:0.0.0.0 \
    --rollup.sequencerhttp=SEQUENCER_HTTP \
    --rollup.halt=major \
    --port=30303 \
    --rollup.disabletxpoolgossip=true
```

Refer to the `op-geth` configuration [documentation](https://docs.optimism.io/builders/node-operators/management/configuration#op-geth) for detailed information about available options.

#### Run op-reth

Navigate to your `reth` directory and start service by running the command:

For, Lisk Sepolia Testnet:

```sh
./target/release/op-reth node \
  -vvv \
  --datadir="$DATADIR_PATH" \
  --log.stdout.format log-fmt \
  --ws \
  --ws.origins="*" \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.api=debug,eth,net,txpool \
  --http \
  --http.corsdomain="*" \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=debug,eth,net,txpool \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=PATH_TO_JWT_TEXT_FILE \
  --metrics=0.0.0.0:6060 \
  --chain=PATH_TO_NETWORK_GENESIS_FILE \
  --disable-discovery \
  --rollup.sequencer-http=SEQUENCER_HTTP \
  --rollup.disable-tx-pool-gossip \
  --override.canyon=0
```

For, Lisk Mainnet:

```sh
./target/release/op-reth node \
  -vvv \
  --datadir="$DATADIR_PATH" \
  --log.stdout.format log-fmt \
  --ws \
  --ws.origins="*" \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.api=debug,eth,net,txpool \
  --http \
  --http.corsdomain="*" \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=debug,eth,net,txpool \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=PATH_TO_JWT_TEXT_FILE \
  --metrics=0.0.0.0:6060 \
  --chain=PATH_TO_NETWORK_GENESIS_FILE \
  --disable-discovery \
  --rollup.sequencer-http=SEQUENCER_HTTP \
  --rollup.disable-tx-pool-gossip
```

Refer to the `reth` configuration [documentation](https://reth.rs/cli/reth/node.html#reth-node) for detailed information about available options.

> **Note**: Official Lisk sequencer HTTP:
> <br>For Mainnet: https://rpc.sepolia-api.lisk.com
> <br>For Sepolia Testnet: https://rpc.api.lisk.com

#### Run op-node

Navigate to your `op-node` directory and start service by running the command:

**Note**:

- Please make sure to patch your `op-node` with [`lisk-hotfix.patch`](./geth/lisk-hotfix.patch) for an unhandled `SystemConfig` event emitted, affecting the Lisk nodes resulting in error logs. This patch is temporary until our RaaS provider updates the `SystemConfig` contract.
  ```sh
  git apply <path-to-lisk-hotfix.patch>
  ```

For, Lisk Sepolia Testnet:

```sh
./bin/op-node \
  --l1=$OP_NODE_L1_ETH_RPC \
  --l1.rpckind=$OP_NODE_L1_RPC_KIND \
  --l1.beacon=$OP_NODE_L1_BEACON \
  --l2=ws://localhost:8551 \
  --l2.jwt-secret=PATH_TO_JWT_TEXT_FILE \
  --rollup.config=PATH_TO_NETWORK_ROLLUP_FILE
```

For, Lisk Mainnet:

```sh
./bin/op-node \
  --l1=$OP_NODE_L1_ETH_RPC \
  --l1.rpckind=$OP_NODE_L1_RPC_KIND \
  --l1.beacon=$OP_NODE_L1_BEACON \
  --l2=ws://localhost:8551 \
  --l2.jwt-secret=PATH_TO_JWT_TEXT_FILE \
  --rollup.config=PATH_TO_NETWORK_ROLLUP_FILE
```

The above command starts `op-node` in **full sync** mode. Depending on the chain length, the initial sync process could take significant time; varying from days to weeks.

```
INFO [06-26|13:31:20.389] Advancing bq origin                      origin=17171d..1bc69b:8300332 originBehind=false
```

For more information refer to the OP [documentation](https://docs.optimism.io/builders/node-operators/tutorials/mainnet#full-sync).

> **Note**:
> <br>In case you had skipped the `op-geth` [initialization step](#initialize-op-geth) above, you can start the node with the `--network=OP_NODE_NETWORK` flag.
> <br>When specifying the `--network` flag, kindly make sure to remove the `--rollup.config` flag.

Refer to the `op-node` configuration [documentation](https://docs.optimism.io/builders/node-operators/management/configuration#op-node) for detailed information about available options.

> **Note**:
> <br>Some L1 nodes (e.g. Erigon) do not support fetching storage proofs. You can work around this by specifying `--l1.trustrpc` when starting op-node (add it in `op-node-entrypoint` and rebuild the docker image with `docker compose build`.) Do not do this unless you fully trust the L1 node provider.

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
