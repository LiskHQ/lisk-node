FROM golang:1.22 AS op

WORKDIR /app

RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/bin
ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV VERSION=v1.11.1
ENV COMMIT=443e931f242e1595896d6598b02068dc822e1232
RUN git clone $REPO --branch op-node/$VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN cd op-node && \
    make VERSION=$VERSION op-node

FROM rust:1.82 AS reth

ARG FEATURES=jemalloc,asm-keccak,optimism
ARG PROFILE=maxperf

WORKDIR /app

RUN apt-get update && apt-get -y upgrade && apt-get install -y git libclang-dev pkg-config curl build-essential

ENV REPO=https://github.com/paradigmxyz/reth.git
ENV VERSION=v1.2.1
ENV COMMIT=baf5dcc0d51f44a81f5f6a42c093c05511d118b2
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
