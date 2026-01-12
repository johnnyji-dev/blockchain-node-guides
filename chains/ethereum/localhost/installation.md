# Ethereum 노드 설치 가이드

Geth 노드 설치 및 초기 설정에 대한 가이드입니다.

## 목차
- [하드웨어 요구사항](#하드웨어-요구사항)
- [소프트웨어 요구사항](#소프트웨어-요구사항)
- [설치 방법](#설치-방법)
- [초기 동기화](#초기-동기화)
- [설치 확인](#설치-확인)

## 하드웨어 요구사항

### 최소 사양
- **CPU**: 4코어 이상
- **RAM**: 8GB 이상
- **디스크**: 1TB 이상 (SSD 강력 권장)
- **네트워크**: 안정적인 인터넷 연결 (최소 100Mbps)

### 권장 사양
- **CPU**: 8코어 이상
- **RAM**: 16GB 이상
- **디스크**: 2TB 이상 SSD
- **네트워크**: 광대역 인터넷 연결 (500Mbps 이상)

## 소프트웨어 요구사항

- **운영체제**: Linux (Ubuntu 20.04 LTS 이상), macOS, Windows
- **의존성**: 
  - build-essential (Linux)
  - golang (소스 빌드 시)

## 설치 방법

### 방법 1: 바이너리 다운로드 (권장)

#### Linux
```bash
# 최신 버전 다운로드
# Geth 공식 다운로드 페이지에서 최신 버전 확인
# https://geth.ethereum.org/downloads

# 예시: Geth 1.13.15
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.15.tar.gz

# 압축 해제
tar -xzf geth-linux-amd64-1.13.15.tar.gz

# 설치
sudo install -m 0755 -o root -g root geth /usr/local/bin/

# 설치 확인
geth version
```

#### macOS

**방법 A: Homebrew 사용 (권장)**
```bash
# Homebrew를 통한 설치
brew install ethereum
```

**방법 B: 바이너리 다운로드**
```bash
# 최신 버전 다운로드 (macOS용)
# 예시: Geth 1.13.15
curl -O https://gethstore.blob.core.windows.net/builds/geth-darwin-amd64-1.13.15.tar.gz

# 압축 해제
tar -xzf geth-darwin-amd64-1.13.15.tar.gz

# 설치
sudo cp geth /usr/local/bin/
sudo chmod +x /usr/local/bin/geth

# 설치 확인
geth version
```

### 방법 2: 소스 코드에서 빌드

```bash
# Go 설치 (필요한 경우)
# https://golang.org/dl/ 에서 최신 버전 다운로드

# 저장소 클론
git clone https://github.com/ethereum/go-ethereum.git
cd go-ethereum

# 빌드
make geth

# 설치
sudo cp build/bin/geth /usr/local/bin/
```

### 방법 3: 패키지 매니저 사용 (Ubuntu/Debian)

```bash
# 공식 저장소 추가
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update

# Geth 설치
sudo apt-get install ethereum

# 설치 확인
geth version
```

## 초기 동기화

Ethereum 노드를 처음 실행하면 전체 블록체인을 다운로드해야 합니다.

```bash
# Geth 실행 (메인넷)
geth --mainnet --datadir ~/.ethereum --syncmode snap

# 또는 백그라운드 실행
nohup geth --mainnet --datadir ~/.ethereum --syncmode snap > geth.log 2>&1 &

# 동기화 상태 확인
geth attach --exec 'eth.syncing'
```

**참고**: 초기 동기화는 수일이 소요될 수 있습니다. snap sync 모드를 사용하면 시간을 단축할 수 있습니다.

## 설치 확인

```bash
# 버전 확인
geth version

# 블록체인 정보 확인
geth attach --exec 'eth.blockNumber'

# 네트워크 정보 확인
geth attach --exec 'net.peerCount'
```

## 다음 단계

설치가 완료되면 [설정 가이드](./configuration.md)를 참고하여 노드를 구성하세요.
