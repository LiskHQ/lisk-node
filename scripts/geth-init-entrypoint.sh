#!/bin/bash
set -eu

GETH_DATA_DIR=/data
mkdir -p $GETH_DATA_DIR

# Init genesis
exec ./geth init --datadir=$GETH_DATA_DIR "$OP_GETH_GENESIS_FILE_PATH"
