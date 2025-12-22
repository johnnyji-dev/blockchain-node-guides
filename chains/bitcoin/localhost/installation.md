# Bitcoin 노드 설치 가이드

Bitcoin Core 노드 설치 및 초기 설정에 대한 가이드입니다.

## 목차
- [하드웨어 요구사항](#하드웨어-요구사항)
- [소프트웨어 요구사항](#소프트웨어-요구사항)
- [설치 방법](#설치-방법)
- [초기 동기화](#초기-동기화)
- [설치 확인](#설치-확인)

## 하드웨어 요구사항

### 최소 사양
- **CPU**: 2코어 이상
- **RAM**: 4GB 이상
- **디스크**: 500GB 이상 (SSD 권장)
- **네트워크**: 안정적인 인터넷 연결 (최소 50Mbps)

### 권장 사양
- **CPU**: 4코어 이상
- **RAM**: 8GB 이상
- **디스크**: 1TB 이상 SSD
- **네트워크**: 광대역 인터넷 연결 (100Mbps 이상)

## 소프트웨어 요구사항

- **운영체제**: Linux (Ubuntu 20.04 LTS 이상), macOS, Windows
- **의존성**: 
  - build-essential (Linux)
  - libssl-dev
  - libboost-all-dev
  - libevent-dev

## 설치 방법

### 방법 1: 바이너리 다운로드 (권장)

#### Linux
```bash
# 최신 버전 다운로드
wget https://bitcoincore.org/bin/bitcoin-core-[버전]/bitcoin-[버전]-x86_64-linux-gnu.tar.gz

# 압축 해제
tar -xzf bitcoin-[버전]-x86_64-linux-gnu.tar.gz

# 설치
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-[버전]/bin/*
```

#### macOS
```bash
# Homebrew를 통한 설치
brew install bitcoin
```

### 방법 2: 소스 코드에서 빌드

```bash
# 저장소 클론
git clone https://github.com/bitcoin/bitcoin.git
cd bitcoin

# 의존성 설치 (Ubuntu/Debian)
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3

# 빌드
./autogen.sh
./configure
make

# 설치
sudo make install
```

## 초기 동기화

Bitcoin 노드를 처음 실행하면 전체 블록체인을 다운로드해야 합니다.

```bash
# Bitcoin Core 실행
bitcoind -daemon

# 동기화 상태 확인
bitcoin-cli getblockchaininfo
```

**참고**: 초기 동기화는 수일이 소요될 수 있습니다. 스냅샷을 사용하면 시간을 단축할 수 있습니다.

## 설치 확인

```bash
# 버전 확인
bitcoin-cli --version

# 블록체인 정보 확인
bitcoin-cli getblockchaininfo

# 네트워크 정보 확인
bitcoin-cli getnetworkinfo
```

## 다음 단계

설치가 완료되면 [설정 가이드](./configuration.md)를 참고하여 노드를 구성하세요.

