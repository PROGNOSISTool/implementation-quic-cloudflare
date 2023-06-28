# Adapted from https://github.com/cloudflare/quiche/blob/master/Dockerfile
FROM rust:1.66 as build

WORKDIR /build

COPY src/ ./src/
COPY Cargo.toml ./

RUN apt-get update && apt-get install -y cmake golang-go && \
    rm -rf /var/lib/apt/lists/*

RUN cargo build -Z sparse-registry

##
## quiche-base: quiche image for apps
##
FROM debian:latest as quiche-base

RUN apt-get update && apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build \
     /build/target/debug/quiche-server \
     /usr/local/bin/

COPY --from=build \
     /build/src/bin/cert.crt \
     /build/src/bin/cert.key \
     /build/src/bin/rootCA.crt \
     ./crypto/

RUN cp ./crypto/rootCA.crt /usr/local/share/ca-certificates/ && update-ca-certificates

ENV PATH="/usr/local/bin/:${PATH}"
ENV RUST_LOG=info

RUN mkdir web && echo "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis sit amet semper libero, ac auctor leo." > web/index.html

ENTRYPOINT ["quiche-server"]
CMD ["--cert", "./crypto/cert.crt", \
    "--key", "./crypto/cert.key", \
    "--name", "quic.tiferrei.com", \
    "--listen", "0.0.0.0:4433", \
    "--root", "./web", \
    "--dump-packets", "/output", \
    "--no-grease", \
    "--no-retry"]
