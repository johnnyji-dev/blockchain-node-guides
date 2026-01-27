# Stellar Node Dockerfile
# stellar-core (Core Node) + horizon (API Server) 통합 이미지
# Based on official stellar-core installation guide

FROM ubuntu:24.04

# 환경변수 설정
ARG GIT_VERSION
ENV STELLAR_CORE_VERSION=v25.1.0
ENV HORIZON_VERSION=v25.0.0
ENV GO_VERSION=1.23.5
ENV RUST_VERSION=1.74.0
ENV WORKDIR=/opt/stellar
ENV DATADIR=/var/lib/stellar
ENV DAEMONUSER=stellar
ENV DEBIAN_FRONTEND=noninteractive

LABEL BC_NODE_VERSION=$STELLAR_CORE_VERSION
LABEL BC_NODE_GIT_VERSION=$GIT_VERSION
LABEL BC_NODE_TICKER=xlm

# 기본 패키지 설치 (공식 문서 기준)
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
    git \
    build-essential \
    pkg-config \
    autoconf \
    automake \
    libtool \
    bison \
    flex \
    libpq-dev \
    libunwind-dev \
    libgoogle-perftools-dev \
    parallel \
    sed \
    perl \
    wget \
    curl \
    openssl \
    ca-certificates \
    gosu \
    postgresql-client \
    software-properties-common \
    gnupg \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# LLVM 20 저장소 추가 및 clang-20 설치
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc && \
    add-apt-repository -y "deb http://apt.llvm.org/noble/ llvm-toolchain-noble-20 main" && \
    apt-get update && \
    apt-get install -y \
    clang-20 \
    llvm-20 \
    libc++-20-dev \
    libc++abi-20-dev \
    libclang-rt-20-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Rust 설치 (cargo >= 1.74, rust >= 1.74 필요)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION}
ENV PATH="/root/.cargo/bin:${PATH}"

# Go 설치 (horizon 빌드에 필요)
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# 유저, 폴더 설정
RUN useradd -r -m -s /bin/bash $DAEMONUSER && \
    mkdir -p $WORKDIR $DATADIR/core $DATADIR/horizon && \
    chown -R $DAEMONUSER:$DAEMONUSER $WORKDIR $DATADIR

VOLUME $DATADIR
WORKDIR $WORKDIR

# stellar-core 빌드 (공식 문서의 clang + libc++ 방식)
RUN git clone --depth 1 --branch ${STELLAR_CORE_VERSION} https://github.com/stellar/stellar-core.git stellar-core-build && \
    cd stellar-core-build && \
    git submodule init && \
    git submodule update && \
    ./autogen.sh && \
    export CC=clang-20 && \
    export CXX=clang++-20 && \
    export CFLAGS="-O3 -g1 -fno-omit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS -stdlib=libc++" && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf stellar-core-build

# horizon 빌드
RUN git clone --depth 1 --branch ${HORIZON_VERSION} https://github.com/stellar/stellar-horizon.git stellar-horizon && \
    cd stellar-horizon && \
    go build -o /usr/local/bin/horizon . && \
    cd .. && \
    rm -rf stellar-horizon

# 설정 파일 복사
COPY --chown=$DAEMONUSER:$DAEMONUSER stellar-core.cfg $WORKDIR/
COPY --chown=$DAEMONUSER:$DAEMONUSER launcher.sh $WORKDIR/
RUN chmod +x $WORKDIR/launcher.sh

# 포트 노출
# 11625: stellar-core P2P
# 11626: stellar-core HTTP (관리용)
# 8000: horizon API
EXPOSE 11625 11626 8000

# 작업 디렉토리 설정
WORKDIR $WORKDIR

# 헬스체크
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
  CMD curl -f http://localhost:11626/info || exit 1

# launcher 실행
CMD ["./launcher.sh"]
