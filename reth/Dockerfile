FROM golang:1.22 AS op

WORKDIR /app

RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/bin
ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV VERSION=v1.13.0
ENV COMMIT=5f003211aed7469eed7df666291a62c025d1c46c
RUN git clone $REPO --branch op-node/$VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN cd op-node && \
    make VERSION=$VERSION op-node

FROM rust:1.85 AS reth

ARG FEATURES=jemalloc,asm-keccak
ARG PROFILE=maxperf

WORKDIR /app

RUN apt-get update && apt-get -y upgrade && apt-get install -y git libclang-dev pkg-config curl build-essential

ENV REPO=https://github.com/paradigmxyz/reth.git
ENV VERSION=v1.3.11
ENV COMMIT=e0e85aa10b98fa92d32c3e820c7ed2cee0b02931
RUN git clone $REPO --branch $VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN RUSTFLAGS="-C target-cpu=native" cargo build --bin op-reth --locked --features $FEATURES --profile $PROFILE --manifest-path crates/optimism/bin/Cargo.toml

FROM ubuntu:22.04

ARG PROFILE=maxperf

RUN apt-get update && \
    apt-get install -y jq curl supervisor && \
    rm -rf /var/lib/apt/lists
RUN mkdir -p /var/log/supervisor

WORKDIR /app

COPY --from=op /app/op-node/bin/op-node ./
COPY --from=reth /app/target/$PROFILE/op-reth ./
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./reth/reth-entrypoint ./execution-entrypoint
COPY ./reth/download-apply-snapshot.sh .
COPY op-node-entrypoint .
COPY sepolia ./sepolia
COPY mainnet ./mainnet

CMD ["/usr/bin/supervisord"]
