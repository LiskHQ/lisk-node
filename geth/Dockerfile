FROM golang:1.21 AS op

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV VERSION=v1.9.3
ENV COMMIT=e81c50de0a51954c64444b849be4768c8116cffb
RUN git clone $REPO --branch op-node/$VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

# Patch to handle the legacy ConfigUpdate event GAS_CONFIG_ECOTONE that shouldn't be used anymore
# Emitted only on Lisk Sepolia from the SystemConfig contract
COPY op-node-lisk-hotfix.patch .
RUN git apply op-node-lisk-hotfix.patch && \
    cd op-node && \
    make VERSION=$VERSION op-node

FROM golang:1.21 AS geth

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/op-geth.git
ENV VERSION=v1.101408.0
ENV COMMIT=5c2e75862239c77d2873de1888ba52ee84c83178
RUN git clone $REPO --branch $VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN go run build/ci.go install -static ./cmd/geth

FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y jq curl supervisor && \
    rm -rf /var/lib/apt/lists
RUN mkdir -p /var/log/supervisor

WORKDIR /app

COPY --from=op /app/op-node/bin/op-node ./
COPY --from=geth /app/build/bin/geth ./
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY geth/geth-entrypoint ./execution-entrypoint
COPY geth/download-apply-snapshot.sh .
COPY op-node-entrypoint .
COPY sepolia ./sepolia
COPY mainnet ./mainnet

CMD ["/usr/bin/supervisord"]
