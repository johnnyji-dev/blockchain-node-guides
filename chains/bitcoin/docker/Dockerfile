# Bitcoin Core Node Dockerfile
# Ubuntu-based Bitcoin Core node image

FROM ubuntu:22.04

# Environment variables
ENV BITCOIN_VERSION=26.0
ENV BITCOIN_DATA_DIR=/home/bitcoin/.bitcoin
ENV BITCOIN_USER=bitcoin
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create Bitcoin user
RUN useradd -m -s /bin/bash ${BITCOIN_USER}

# Download and install Bitcoin Core
RUN BITCOIN_TARBALL="bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" && \
    wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/${BITCOIN_TARBALL} && \
    wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc && \
    tar -xzf ${BITCOIN_TARBALL} && \
    install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${BITCOIN_VERSION}/bin/* && \
    rm -rf ${BITCOIN_TARBALL} bitcoin-${BITCOIN_VERSION}

# Create data directory and set permissions
RUN mkdir -p ${BITCOIN_DATA_DIR} && \
    chown -R ${BITCOIN_USER}:${BITCOIN_USER} ${BITCOIN_DATA_DIR}

# Expose ports
# 8333: P2P network port
# 8332: RPC port
EXPOSE 8333 8332

# Volume mount point
VOLUME ["${BITCOIN_DATA_DIR}"]

# Switch to Bitcoin user
USER ${BITCOIN_USER}

# Set working directory
WORKDIR ${BITCOIN_DATA_DIR}

# Healthcheck configuration
# Note: Healthcheck in Dockerfile will be overridden by docker-compose.yml
# Using cookie file method (more secure) - bitcoind automatically creates .cookie file
HEALTHCHECK --interval=60s --timeout=10s --start-period=300s --retries=3 \
    CMD bitcoin-cli -rpccookiefile=/home/bitcoin/.bitcoin/.cookie getblockchaininfo 2>/dev/null || exit 1

# Default command
# Configuration file should be mounted via docker-compose or at runtime
CMD ["bitcoind", "-printtoconsole"]

