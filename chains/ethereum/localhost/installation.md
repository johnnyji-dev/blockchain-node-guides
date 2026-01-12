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

### Execution Layer (Geth 설치

#### 방법 1: GitHub 릴리스에서 바이너리 다운로드 (권장)

**최신 버전 확인**: [https://github.com/ethereum/go-ethereum/releases](https://github.com/ethereum/go-ethereum/releases)

##### Linux
```bash
# 최신 버전 확인 후 다운로드
# 예시: Geth v1.16.7 (최신 버전은 GitHub 릴리스 페이지에서 확인)
GETH_VERSION="1.16.7"
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-${GETH_VERSION}.tar.gz

# 압축 해제
tar -xzf geth-linux-amd64-${GETH_VERSION}.tar.gz

# 설치
sudo install -m 0755 -o root -g root geth /usr/local/bin/

# 설치 확인
geth version
```

##### macOS
```bash
# 최신 버전 확인 후 다운로드
# 예시: Geth v1.16.7
GETH_VERSION="1.16.7"
curl -O https://gethstore.blob.core.windows.net/builds/geth-darwin-amd64-${GETH_VERSION}.tar.gz

# 압축 해제
tar -xzf geth-darwin-amd64-${GETH_VERSION}.tar.gz

# 설치
sudo cp geth /usr/local/bin/
sudo chmod +x /usr/local/bin/geth

# 설치 확인
geth version
```

#### macOS (Homebrew 사용)

```bash
# Homebrew를 통한 설치 (최신 버전 자동 설치)
brew install ethereum

# 설치 확인
geth version
```

### 방법 2: 소스 코드에서 빌드

```bash
# Go 설치 (필요한 경우)
# https://golang.org/dl/ 에서 최신 버전 다운로드
# Go 1.24 이상 필요 (Geth v1.16.x 기준)

# 저장소 클론
git clone https://github.com/ethereum/go-ethereum.git
cd go-ethereum

# 특정 버전 체크아웃 (선택사항)
# git checkout v1.16.7

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

### Consensus Layer (Prysm) 설치

**참고**: 완전한 Ethereum 노드를 운영하려면 Execution Layer(Geth)와 Consensus Layer(Prysm)를 모두 설치해야 합니다.

#### 최신 버전 확인
- **공식 릴리스**: [https://github.com/prysmaticlabs/prysm/releases](https://github.com/prysmaticlabs/prysm/releases)
- **최신 버전**: v7.1.2 (2026년 1월 기준)

#### Linux 바이너리 다운로드

```bash
# 최신 버전 확인 후 다운로드
# 예시: Prysm v7.1.2
PRYSM_VERSION="v7.1.2"

# Beacon Chain 바이너리 다운로드
wget https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}/beacon-chain-${PRYSM_VERSION}-linux-amd64

# Validator Client 바이너리 다운로드 (검증자 운영 시)
wget https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}/validator-${PRYSM_VERSION}-linux-amd64

# 실행 권한 부여
chmod +x beacon-chain-${PRYSM_VERSION}-linux-amd64
chmod +x validator-${PRYSM_VERSION}-linux-amd64

# 심볼릭 링크 생성 (선택사항)
sudo ln -s $(pwd)/beacon-chain-${PRYSM_VERSION}-linux-amd64 /usr/local/bin/beacon-chain
sudo ln -s $(pwd)/validator-${PRYSM_VERSION}-linux-amd64 /usr/local/bin/validator
```

#### macOS 바이너리 다운로드

```bash
# 최신 버전 확인 후 다운로드
PRYSM_VERSION="v7.1.2"

# Beacon Chain 바이너리 다운로드
curl -O -L https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}/beacon-chain-${PRYSM_VERSION}-darwin-amd64

# Validator Client 바이너리 다운로드
curl -O -L https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}/validator-${PRYSM_VERSION}-darwin-amd64

# 실행 권한 부여
chmod +x beacon-chain-${PRYSM_VERSION}-darwin-amd64
chmod +x validator-${PRYSM_VERSION}-darwin-amd64
```

## 초기 동기화

### Execution Layer (Geth) 동기화

Ethereum Execution Layer를 처음 실행하면 전체 블록체인을 다운로드해야 합니다.

```bash
# Geth 실행 (메인넷)
geth --mainnet --datadir ~/.ethereum --syncmode snap

# 또는 백그라운드 실행
nohup geth --mainnet --datadir ~/.ethereum --syncmode snap > geth.log 2>&1 &

# 동기화 상태 확인
geth attach --exec 'eth.syncing'
```

**참고**: 초기 동기화는 수일이 소요될 수 있습니다. snap sync 모드를 사용하면 시간을 단축할 수 있습니다.

### Consensus Layer (Prysm) 동기화

Prysm은 Execution Layer와 통신하여 합의 레이어를 동기화합니다.

```bash
# Beacon Chain 실행 (Execution Layer와 통신)
./beacon-chain --mainnet \
  --execution-endpoint=http://localhost:8551 \
  --jwt-secret=/path/to/jwt-secret \
  --datadir=~/.prysm

# 동기화 상태 확인
curl http://localhost:3500/eth/v1/node/syncing
```

**중요**: 
- Execution Layer(Geth)가 먼저 실행되어야 합니다
- JWT secret 파일이 필요합니다 (Geth와 공유)
- Execution API 엔드포인트가 올바르게 설정되어야 합니다

## 설치 확인

### Execution Layer (Geth) 확인

```bash
# 버전 확인
geth version

# 블록체인 정보 확인
geth attach --exec 'eth.blockNumber'

# 네트워크 정보 확인
geth attach --exec 'net.peerCount'

# 동기화 상태 확인
geth attach --exec 'eth.syncing'
```

### Consensus Layer (Prysm) 확인

```bash
# Beacon Chain 버전 확인
./beacon-chain --version

# 동기화 상태 확인 (API)
curl http://localhost:3500/eth/v1/node/syncing

# 피어 정보 확인
curl http://localhost:3500/eth/v1/node/peers
```

## 다음 단계

설치가 완료되면 [설정 가이드](./configuration.md)를 참고하여 노드를 구성하세요.
