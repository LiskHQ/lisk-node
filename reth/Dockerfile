ARG GOLANG_VERSION=1.26
ARG RUST_VERSION=1.94
ARG UBUNTU_VERSION=25.04

FROM golang:$GOLANG_VERSION AS op

WORKDIR /app

RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/bin
RUN apt-get update && apt-get install -y jq zip && rm -rf /var/lib/apt/lists/*
ENV YQ_VERSION=v4.44.1
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) YQ_SHA256=6dc2d0cd4e0caca5aeffd0d784a48263591080e4a0895abe69f3a76eb50d1ba3 ;; \
      arm64) YQ_SHA256=8c12fcc10e14774ca6624cc282f092a526568b036fe1192258c3aecbad56d063 ;; \
      *) echo "unsupported arch: $ARCH" >&2; exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" -o /usr/bin/yq && \
    echo "${YQ_SHA256}  /usr/bin/yq" | sha256sum -c - && \
    chmod +x /usr/bin/yq
ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV VERSION=v1.19.3
ENV COMMIT=7f91e599c89fa309850f44debcd8ba84b98164e0
RUN git clone $REPO --branch op-node/$VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

# op-node embeds superchain-configs.zip, generated from the superchain-registry
# submodule (gitignored in the source tree, so it must be built here).
RUN just build-superchain-go

RUN cd op-node && \
    make VERSION=$VERSION op-node

FROM rust:$RUST_VERSION AS reth

ARG FEATURES=jemalloc,asm-keccak
ARG PROFILE=maxperf

WORKDIR /app

RUN apt-get update && apt-get -y upgrade && apt-get install -y git libclang-dev pkg-config curl build-essential

ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV VERSION=op-reth/v2.4.1
ENV COMMIT=a9a8dad3f1500a4cc2e4077edb480848bfdef29a
RUN git clone $REPO --branch $VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

# op-reth's superchain-configs feature regenerates res/superchain-configs.tar from
# the superchain-registry submodule at build time (the tar is gitignored upstream).
RUN git submodule update --init --force --depth 1 -- superchain-registry

WORKDIR /app/rust/op-reth

RUN RUSTFLAGS="-C target-cpu=native" cargo build --bin op-reth --locked --features $FEATURES --profile $PROFILE --manifest-path bin/Cargo.toml

FROM ubuntu:$UBUNTU_VERSION

ARG PROFILE=maxperf

RUN apt-get update && \
    apt-get install -y jq curl lz4 supervisor && \
    rm -rf /var/lib/apt/lists
RUN mkdir -p /var/log/supervisor

WORKDIR /app

COPY --from=op /app/op-node/bin/op-node ./
COPY --from=reth /app/rust/target/$PROFILE/op-reth ./
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./reth/reth-entrypoint ./execution-entrypoint
COPY ./reth/download-apply-snapshot.sh .
COPY op-node-entrypoint .

CMD ["/usr/bin/supervisord"]
