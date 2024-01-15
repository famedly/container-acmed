# syntax=docker/dockerfile-upstream:1.5-labs

FROM rust:bullseye as builder

RUN cargo install cargo-auditable

WORKDIR /build
ADD . .
RUN git submodule update --init --recursive

WORKDIR /build/modules/acmed
RUN cargo auditable build --release

WORKDIR /build/modules/ssh
RUN cargo auditable build --release

WORKDIR /build/modules/rfc2136
RUN cargo auditable build --release


FROM debian:bullseye-slim
ARG TARGETPLATFORM

RUN apt-get update && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/modules/acmed/target/release/acmed /usr/local/bin/acmed
COPY --from=builder /build/modules/acmed/target/release/tacd  /usr/local/bin/tacd
COPY --from=builder /build/modules/ssh/target/release/acmed-send-cert  /usr/local/bin/acmed-send-cert
COPY --from=builder /build/modules/rfc2136/target/release/acmed-hook-rfc2136  /usr/local/bin/acmed-hook-rfc2136
ADD --chmod=0644 acmed.toml /etc/acmed/acmed.toml

VOLUME /opt/acmed
CMD ["/usr/local/bin/acmed", "-f", "--log-stderr"]

LABEL org.opencontainers.image.title="acmed"
LABEL org.opencontainers.image.description="an acmed container with famedly/acmed-hook-ssh and famedly/acmed-hook-rfc2136 included"




