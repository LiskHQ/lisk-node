#!/bin/bash
set +e
set -u

# Set alias for echoBanner if unavailable - for local testing
[[ $(type -t echoBanner) == function ]] || alias echoBanner=echo

# Translate APPLY_SNAPSHOT to uppercase; default to FALSE
readonly APPLY_SNAPSHOT=$(echo "${APPLY_SNAPSHOT:-false}" | tr "[:lower:]" "[:upper:]")

if [[ "$APPLY_SNAPSHOT" == "FALSE" ]]; then
  echo "Automatic snapshot application disabled; to enable, set 'APPLY_SNAPSHOT=true' and restart"
  exit 0
fi

if [[ "${RETH_DATA_DIR-x}" == x ]]; then
  echo "RETH_DATA_DIR is undefined"
  exit 1
fi

if [[ "${CLIENT}" != "reth" ]]; then
  echo "Error: this script is only for reth"
  exit 14
fi

# Snapshot base URLs
readonly SNAPSHOT_BASE_URL_DEFAULT="https://snapshots.lisk.com"
readonly SNAPSHOT_BASE_URL_ALTERNATE="https://s3.eu-west-3.amazonaws.com/snapshots.lisk.com"

# Automatically resolve SNAPSHOT_URL, if not specified
SNAPSHOT_URL="$SNAPSHOT_URL"
if [[ "${SNAPSHOT_URL-x}" == x || -z $SNAPSHOT_URL ]];
then
  readonly SNAPSHOT_URL_BASE="$SNAPSHOT_BASE_URL_DEFAULT/$SNAPSHOT_NETWORK"
  readonly LATEST_SNAPSHOT_NAME=$(curl --silent --location $SNAPSHOT_URL_BASE/latest-${CLIENT}-${SNAPSHOT_TYPE})
  SNAPSHOT_URL="$SNAPSHOT_URL_BASE/$LATEST_SNAPSHOT_NAME"
  echo "SNAPSHOT_URL not specified; automatically resolved to $SNAPSHOT_URL"
fi

# Update SNAPSHOT_URL to alternate URL, if it uses the default base URL and it doesn't respond
readonly http_code=$(curl -o /dev/null --silent -Iw '%{http_code}' $SNAPSHOT_URL)
if [[ "$http_code" != "200" ]];
then
  echo "Unable to access $SNAPSHOT_URL"
  if [[ $SNAPSHOT_URL =~ $SNAPSHOT_BASE_URL_DEFAULT ]];
  then
    readonly SNAPSHOT_URL=$(echo "${SNAPSHOT_URL/$SNAPSHOT_BASE_URL_DEFAULT/$SNAPSHOT_BASE_URL_ALTERNATE}")
    echo "Updating SNAPSHOT_URL to $SNAPSHOT_URL"
  else
    echo "Try using the official URL instead. Exiting snapshot download & application..."
    exit 2
  fi
fi

readonly SNAPSHOT_DIR=./snapshot
readonly SNAPSHOT_REMOTE_FILENAME=$(basename ${SNAPSHOT_URL})
readonly SNAPSHOT_SHA256_URL="${SNAPSHOT_URL}.SHA256"
readonly SNAPSHOT_SHA256_FILENAME="${SNAPSHOT_REMOTE_FILENAME}.SHA256"
readonly SNAPSHOT_DOWNLOAD_MAX_TRIES=3

# Verify that the snapshot is a datadir snapshot
if [[ $SNAPSHOT_REMOTE_FILENAME != *datadir*.tar.gz ]]; then
  echo "Error: Reth only supports datadir snapshots. The provided snapshot appears to be an export snapshot."
  exit 13
fi

# Clear any existing snapshots
rm -rf $SNAPSHOT_DIR

# Download the snapshot & the checksum file
echoBanner "Downloading snapshot to '${SNAPSHOT_DIR}/${SNAPSHOT_REMOTE_FILENAME}' from '${SNAPSHOT_URL}'..."
num_tries_left=$SNAPSHOT_DOWNLOAD_MAX_TRIES
download_and_verify(){
  echo -e "Number of tries left: ${num_tries_left}"
  : $((--num_tries_left)) # Reduce num_tries_left

  echo -e "\nDownloading snapshot..."
  curl --create-dirs --output $SNAPSHOT_DIR/$SNAPSHOT_REMOTE_FILENAME --location $SNAPSHOT_URL

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

# Extract the datadir snapshot
echoBanner "Importing snapshot..."
echo "Extracting reth data directory snapshot to ${RETH_DATA_DIR}..."
tar --directory $RETH_DATA_DIR -xf $SNAPSHOT_DIR/$SNAPSHOT_REMOTE_FILENAME
readonly SNAPSHOT_IMPORT_EXIT_CODE=$?

echo -e "\nRemoving the temporary snapshot download directory: '${SNAPSHOT_DIR}'"
rm -rf $SNAPSHOT_DIR

if [[ "$SNAPSHOT_IMPORT_EXIT_CODE" == "0" ]]; then
  echo "Snapshot successfully imported"
else
  echo "Snapshot import failed. Skipping snapshot application..."
  exit 12
fi
