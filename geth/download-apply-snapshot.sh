#!/bin/bash
set -eu

# Set alias for echoBanner if unavailable - for local testing
[[ $(type -t echoBanner) == function ]] || alias echoBanner=echo

# Translate APPLY_SNAPSHOT to uppercase; default to FALSE
readonly APPLY_SNAPSHOT=$(echo "${APPLY_SNAPSHOT:-false}" | tr "[:lower:]" "[:upper:]")

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

readonly SNAPSHOT_DIR=./snapshot
readonly SNAPSHOT_FILENAME=$(basename ${SNAPSHOT_URL})
readonly SNAPSHOT_SHA256_URL="${SNAPSHOT_URL}.SHA256"
readonly SNAPSHOT_SHA256_FILENAME="${SNAPSHOT_FILENAME}.SHA256"
readonly SNAPSHOT_DOWNLOAD_MAX_TRIES=3

# Clear any existing snapshots
rm -rf $SNAPSHOT_DIR

# Download the snapshot & the checksum file
echoBanner "Downloading snapshot to '${SNAPSHOT_DIR}/$SNAPSHOT_FILENAME' from '${SNAPSHOT_URL}'..."
num_tries_left=$SNAPSHOT_DOWNLOAD_MAX_TRIES
download_and_verify(){
  echo -e "Number of tries left: ${num_tries_left}"
  : $((--num_tries_left)) # Reduce num_tries_left

  echo -e "\nDownloading snapshot..."
  curl --create-dirs --output $SNAPSHOT_DIR/$SNAPSHOT_FILENAME --location $SNAPSHOT_URL

  echo -e "\nDownloading snapshot checksum..."
  curl --create-dirs --output $SNAPSHOT_DIR/$SNAPSHOT_SHA256_FILENAME --location $SNAPSHOT_SHA256_URL

  echo -e "\nVerifying integrity of the downloaded snapshot..."
  if command -v sha256sum &>/dev/null; then
    (cd $SNAPSHOT_DIR && sha256sum --check $SNAPSHOT_SHA256_FILENAME &>/dev/null)
  elif command -v shasum &>/dev/null; then
    (cd $SNAPSHOT_DIR && shasum --algorithm 256 --check $SNAPSHOT_SHA256_FILENAME &>/dev/null)
  else
    echo "Neither sha256sum nor shasum available. Skipping..."
    return 9
  fi

  if [[ "$?" != "0" ]]; then
    echo "Snapshot is corrupted. Skipping snapshot application..."
    return 10
  fi

  echo "Snapshot successfully downloaded and verified"
}
for i in $(seq 1 $SNAPSHOT_DOWNLOAD_MAX_TRIES); do download_and_verify && returncode=0 && break || returncode=$? && sleep 10; done; (exit $returncode)

# Import snapshot
echoBanner "Importing snapshot..."
./geth import --syncmode "${OP_GETH_SYNCMODE:-full}" --datadir=$GETH_DATA_DIR $SNAPSHOT_DIR/$SNAPSHOT_FILENAME
if [[ "$?" == "0" ]]; then
  echo "Snapshot successfully imported"
else
  echo "Snapshot import failed. Skipping snapshot application..."
  exit 11
fi