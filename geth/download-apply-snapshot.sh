#!/bin/bash
set -eu

# Set alias for echoBanner if unavailable - for local testing
[[ $(type -t echoBanner) == function ]] || alias echoBanner=echo

# Translate APPLY_SNAPSHOT to uppercase; default to FALSE
APPLY_SNAPSHOT=$(echo "${APPLY_SNAPSHOT-false}" | tr "[:lower:]" "[:upper:]")

if [[ "$APPLY_SNAPSHOT" == "FALSE" ]]; then
  echo "Automatic snapshot application disabled; to enable, set 'APPLY_SNAPSHOT=true' and restart"
  exit 0
fi

if [[ "${SNAPSHOT_URL-x}" == x || -z $SNAPSHOT_URL ]]; then
    echo "APPLY_SNAPSHOT enabled but SNAPSHOT_URL is undefined"
    exit 1
fi

if [[ "${GETH_DATA_DIR-x}" == x ]]; then
    echo "GETH_DATA_DIR is undefined"
    exit 2
fi

SNAPSHOT_DIR=./snapshot
SNAPSHOT_FILENAME=$(basename ${SNAPSHOT_URL})
SNAPSHOT_SHA256_URL="${SNAPSHOT_URL}.SHA256"
SNAPSHOT_SHA256_FILENAME="${SNAPSHOT_FILENAME}.SHA256"

# Clear any existing snapshots
rm -rf $SNAPSHOT_DIR

# Download the snapshot & the checksum file
echoBanner "Downloading snapshot to '${SNAPSHOT_DIR}/$SNAPSHOT_FILENAME' from '${SNAPSHOT_URL}'..."
curl --create-dirs --output $SNAPSHOT_DIR/$SNAPSHOT_FILENAME --location $SNAPSHOT_URL
curl --create-dirs --output $SNAPSHOT_DIR/$SNAPSHOT_SHA256_FILENAME --location $SNAPSHOT_SHA256_URL

echoBanner "Verifying integrity of the downloaded snapshot..."
if command -v sha256sum &>/dev/null; then
  (cd $SNAPSHOT_DIR && sha256sum --check $SNAPSHOT_SHA256_FILENAME &>/dev/null)
elif command -v shasum &>/dev/null; then
  (cd $SNAPSHOT_DIR && shasum --algorithm 256 --check $SNAPSHOT_SHA256_FILENAME &>/dev/null)
else
  echo "Neither sha256sum nor shasum available. Skipping..."
  exit 9
fi

if [[ "$?" == "0" ]]; then
  echo "Snapshot successfully downloaded and verified"
else
  echo "Snapshot is corrupted. Skipping snapshot application..."
  exit 10
fi

# Import snapshot
echoBanner "Importing snapshot..."
./geth import --datadir=$GETH_DATA_DIR $SNAPSHOT_DIR/$SNAPSHOT_FILENAME
if [[ "$?" == "0" ]]; then
  echo "Snapshot successfully imported"
else
  echo "Snapshot import failed. Skipping snapshot application..."
  exit 11
fi