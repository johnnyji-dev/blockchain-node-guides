# Ethereum Geth Node Dockerfile
# Ubuntu-based Geth node image

FROM ubuntu:22.04

# Environment variables
ENV GETH_VERSION=1.13.15
ENV ETHEREUM_DATA_DIR=/home/ethereum/.ethereum
ENV ETHEREUM_USER=ethereum
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create Ethereum user
RUN useradd -m -s /bin/bash ${ETHEREUM_USER}

# Download and install Geth
RUN GETH_TARBALL="geth-linux-amd64-${GETH_VERSION}.tar.gz" && \
    wget https://gethstore.blob.core.windows.net/builds/${GETH_TARBALL} && \
    tar -xzf ${GETH_TARBALL} && \
    install -m 0755 -o root -g root geth /usr/local/bin/ && \
    rm -rf ${GETH_TARBALL} geth

# Create data directory and set permissions
RUN mkdir -p ${ETHEREUM_DATA_DIR} && \
    chown -R ${ETHEREUM_USER}:${ETHEREUM_USER} ${ETHEREUM_DATA_DIR}

# Expose ports
# 30303: P2P network port (TCP)
# 30303: P2P network port (UDP)
# 8545: HTTP-RPC port
# 8546: WebSocket-RPC port
EXPOSE 30303/tcp 30303/udp 8545 8546

# Volume mount point
VOLUME ["${ETHEREUM_DATA_DIR}"]

# Switch to Ethereum user
USER ${ETHEREUM_USER}

# Set working directory
WORKDIR ${ETHEREUM_DATA_DIR}

# Healthcheck configuration
HEALTHCHECK --interval=60s --timeout=10s --start-period=300s --retries=3 \
    CMD geth attach --exec 'eth.syncing' || exit 1

# Default command
# Configuration file should be mounted via docker-compose or at runtime
CMD ["geth", "--config", "/home/ethereum/.ethereum/geth.toml"]
