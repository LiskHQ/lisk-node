ARG GOLANG_VERSION=1.24
ARG UBUNTU_VERSION=25.04

FROM golang:$GOLANG_VERSION AS op

WORKDIR /app

RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/bin
ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV VERSION=v1.18.2
ENV COMMIT=a5f807798b0896becd497d27b92afe911b088ad4
RUN git clone $REPO --branch op-node/$VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN cd op-node && \
    make VERSION=$VERSION op-node

FROM golang:$GOLANG_VERSION AS geth

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/op-geth.git
ENV VERSION=v1.101702.2
ENV COMMIT=e8800cffe53d459cde8a07c8e8f1de9d86e79e07
RUN git clone $REPO --branch $VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN go run build/ci.go install -static ./cmd/geth

FROM ubuntu:$UBUNTU_VERSION

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

CMD ["/usr/bin/supervisord"]
