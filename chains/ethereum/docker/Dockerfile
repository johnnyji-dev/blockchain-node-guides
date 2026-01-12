# Ethereum Node Dockerfile
# Geth (Execution Layer) + Prysm (Consensus Layer) 통합 이미지

FROM ubuntu:24.04

# 환경변수 설정
ARG GIT_VERSION
ENV GETH_VERSION=1.16.7-b9f3a3d9
ENV PRYSM_VERSION=7.1.2
ENV WORKDIR=/opt/ethereum
ENV DATADIR=/var/lib/coindata
ENV DAEMONUSER=cryptocurrency
ENV DEBIAN_FRONTEND=noninteractive

LABEL BC_NODE_VERSION=$GETH_VERSION
LABEL BC_NODE_GIT_VERSION=$GIT_VERSION
LABEL BC_NODE_TICKER=eth

# 우분투 패키지 설치
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
    wget \
    curl \
    openssl \
    ca-certificates \
    gosu \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 유저, 폴더 설정
RUN useradd -r -m -s /bin/bash $DAEMONUSER && \
    mkdir -p $WORKDIR $DATADIR && \
    chown -R $DAEMONUSER:$DAEMONUSER $WORKDIR $DATADIR

VOLUME $DATADIR
WORKDIR $WORKDIR

# Geth 설치 (geth-alltools 사용 - 모든 도구 포함)
# 공식 다운로드: https://geth.ethereum.org/downloads
# 릴리스 페이지: https://github.com/ethereum/go-ethereum/releases
RUN wget -O geth.tar.gz https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-amd64-${GETH_VERSION}.tar.gz && \
    tar --strip-components=1 -xzf geth.tar.gz && \
    chmod +x geth && \
    rm -f geth.tar.gz

# Prysm 설치
# 공식 릴리스: https://github.com/prysmaticlabs/prysm/releases
RUN wget -O beacon-chain https://github.com/prysmaticlabs/prysm/releases/download/v${PRYSM_VERSION}/beacon-chain-v${PRYSM_VERSION}-linux-amd64 && \
    chmod +x ./beacon-chain

# Validator Client 설치 (선택사항, 검증자 운영 시)
RUN wget -O validator https://github.com/prysmaticlabs/prysm/releases/download/v${PRYSM_VERSION}/validator-v${PRYSM_VERSION}-linux-amd64 && \
    chmod +x ./validator

# JWT secret은 런타임에 생성됩니다 (launcher.sh에서 처리)
# 빌드 시점에 생성하면 macOS에서 Rosetta 에러가 발생할 수 있습니다

# launcher 스크립트 복사
COPY --chown=$DAEMONUSER:$DAEMONUSER launcher.sh $WORKDIR/
RUN chmod +x $WORKDIR/launcher.sh

# 포트 노출
# 30313: Geth P2P (TCP/UDP) - Solana와 충돌 방지
# 3011: Geth Engine API (내부 통신용)
# 3012: Geth HTTP-RPC
# 13010: Prysm P2P (TCP/UDP)
# 4010: Prysm gRPC
# 3510: Prysm HTTP-RPC
EXPOSE 30313/tcp 30313/udp 3011 3012 13010/tcp 13010/udp 4010 3510

# 작업 디렉토리 설정
WORKDIR $WORKDIR

# launcher 실행
CMD ["./launcher.sh"]
