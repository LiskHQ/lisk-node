ARG GOLANG_VERSION=1.24
ARG UBUNTU_VERSION=25.04

FROM golang:$GOLANG_VERSION AS op

WORKDIR /app

RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/bin
ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV VERSION=v1.16.5
ENV COMMIT=3f4294bd62460456e9c952789e1d7453e99dca51
RUN git clone $REPO --branch op-node/$VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN cd op-node && \
    make VERSION=$VERSION op-node

FROM golang:$GOLANG_VERSION AS geth

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/op-geth.git
ENV VERSION=v1.101605.0
ENV COMMIT=f03d103a27f13520f137fb7f80d7dcea7d07123b
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
