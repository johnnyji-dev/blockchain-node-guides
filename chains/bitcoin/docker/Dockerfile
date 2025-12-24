# Bitcoin Core Node Dockerfile
# Ubuntu 기반 Bitcoin Core 노드 이미지

FROM ubuntu:22.04

# 환경 변수 설정
ENV BITCOIN_VERSION=26.0
ENV BITCOIN_DATA_DIR=/home/bitcoin/.bitcoin
ENV BITCOIN_USER=bitcoin
ENV DEBIAN_FRONTEND=noninteractive

# 필수 패키지 설치
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Bitcoin 사용자 생성
RUN useradd -m -s /bin/bash ${BITCOIN_USER}

# Bitcoin Core 다운로드 및 설치
RUN BITCOIN_TARBALL="bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" && \
    wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/${BITCOIN_TARBALL} && \
    wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc && \
    tar -xzf ${BITCOIN_TARBALL} && \
    install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${BITCOIN_VERSION}/bin/* && \
    rm -rf ${BITCOIN_TARBALL} bitcoin-${BITCOIN_VERSION}

# 데이터 디렉토리 생성 및 권한 설정
RUN mkdir -p ${BITCOIN_DATA_DIR} && \
    chown -R ${BITCOIN_USER}:${BITCOIN_USER} ${BITCOIN_DATA_DIR}

# 포트 노출
# 8333: P2P 네트워크 포트
# 8332: RPC 포트
EXPOSE 8333 8332

# 볼륨 마운트 포인트
VOLUME ["${BITCOIN_DATA_DIR}"]

# 비트코인 사용자로 전환
USER ${BITCOIN_USER}

# 작업 디렉토리 설정
WORKDIR ${BITCOIN_DATA_DIR}

# 헬스체크 설정
HEALTHCHECK --interval=60s --timeout=10s --start-period=300s --retries=3 \
    CMD bitcoin-cli getblockchaininfo || exit 1

# 기본 실행 명령
# 설정 파일은 docker-compose나 실행 시 마운트하여 사용
CMD ["bitcoind", "-printtoconsole"]

