FROM golang:1.21 AS op

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV VERSION=v1.9.0
ENV COMMIT=ec45f6634ab2855a4ae5d30c4e240d79f081d689
RUN git clone $REPO --branch op-node/$VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

# Patch to handle the legacy ConfigUpdate event GAS_CONFIG_ECOTONE that shouldn't be used anymore
# Emitted only on Lisk Sepolia from the SystemConfig contract
COPY op-node-lisk-hotfix.patch .
RUN git apply op-node-lisk-hotfix.patch && \
    cd op-node && \
    make VERSION=$VERSION op-node

FROM rust:1.80 AS reth

ARG FEATURES=jemalloc,asm-keccak,optimism
ARG PROFILE=release

WORKDIR /app

RUN apt-get update && apt-get -y upgrade && apt-get install -y git libclang-dev pkg-config curl build-essential

ENV REPO=https://github.com/paradigmxyz/reth.git
ENV VERSION=v1.0.5
ENV COMMIT=603e39ab74509e0863fc023461a4c760fb2126d1
RUN git clone $REPO --branch $VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN cargo build --bin op-reth --locked --features $FEATURES --profile $PROFILE

FROM ubuntu:22.04

ARG PROFILE=release

RUN apt-get update && \
    apt-get install -y jq curl supervisor && \
    rm -rf /var/lib/apt/lists
RUN mkdir -p /var/log/supervisor

WORKDIR /app

COPY --from=op /app/op-node/bin/op-node ./
COPY --from=reth /app/target/$PROFILE/op-reth ./
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./reth/reth-entrypoint ./execution-entrypoint
COPY op-node-entrypoint .
COPY sepolia ./sepolia
COPY mainnet ./mainnet

CMD ["/usr/bin/supervisord"]