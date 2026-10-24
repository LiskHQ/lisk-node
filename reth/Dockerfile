# Matches go.mod's toolchain directive, which the golang image ignores (GOTOOLCHAIN=local).
# A patch pin stops a stale cached golang:1.26 from building op-node without its security fixes.
ARG GOLANG_VERSION=1.26.10
ARG RUST_VERSION=1.95
ARG UBUNTU_VERSION=26.04

FROM golang:$GOLANG_VERSION AS op

WORKDIR /app

# Log builder details to make CI-only image build failures easier to reproduce
# from the job log (architecture, kernel, toolchain and runner differences).
RUN echo "build-info: uid=$(id -u) user=$(id -un) host=$(hostname)" && \
    uname -a && \
    echo "kernel: $(cat /proc/version)" && \
    echo "cpu: $(grep -m4 -E 'model name|^Hardware|CPU implementer|CPU part' /proc/cpuinfo | uniq | tr '\n' ';')" && \
    echo "dmi: $(cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name 2>/dev/null | tr '\n' ';')" && \
    echo "os: $(. /etc/os-release 2>/dev/null; echo $${PRETTY_NAME:-unknown})" && \
    echo "cgroup: $(head -n2 /proc/1/cgroup 2>/dev/null | tr '\n' ';')" && \
    echo "resolv: $(grep -E '^nameserver' /etc/resolv.conf 2>/dev/null | tr '\n' ';')" && \
    echo "route: $(cut -f1 /proc/net/route 2>/dev/null | tail -n +2 | head -n4 | tr '\n' ';')" && \
    echo "disk: $(df -h / | tail -n1)" && \
    (env | grep -viE 'token|secret|passw|credential|key|auth' | sort || true)

# Matches upstream mise.toml. Pinning the tag skips the installer's unauthenticated
# GitHub API lookup, which is rate-limited (403) on shared CI runners.
ENV JUST_VERSION=1.46.0
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --tag $JUST_VERSION --to /usr/bin
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
ENV VERSION=v1.19.11
ENV COMMIT=43c071cbff8ad7512581561aa2d43c990544b650
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
ENV VERSION=op-reth/v2.6.1
ENV COMMIT=e16bffa18420c86dbab693097bc33117f74a5f7d
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
