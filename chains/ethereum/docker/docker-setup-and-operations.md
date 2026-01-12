# Ethereum 노드 Docker 설치 및 운영 가이드

Linux 서버에서 Ethereum 노드를 Docker로 설치하고 운영하는 종합 가이드입니다.

## 목차
- [설치 전 시스템 확인](#설치-전-시스템-확인)
- [Docker 설치 및 설정](#docker-설치-및-설정)
- [Ethereum 노드 Docker 설치](#ethereum-노드-docker-설치)
- [노드 상태 확인](#노드-상태-확인)
- [노드 정보 조회](#노드-정보-조회)
- [트랜잭션 브로드캐스팅](#트랜잭션-브로드캐스팅)
- [문제 해결](#문제-해결)

---

## 설치 전 시스템 확인

Ethereum 노드를 설치하기 전에 시스템이 요구사항을 만족하는지 확인해야 합니다.

### 1. 하드웨어 요구사항 확인

#### 디스크 공간 확인
```bash
# 전체 디스크 사용량 확인
df -h

# 특정 디렉토리 용량 확인
df -h /mnt/cryptocur-data

# Ethereum 블록체인 데이터는 약 1TB 이상 필요 (2024년 기준)
# SSD 사용을 강력히 권장 (HDD는 동기화가 매우 느림)
# 데이터는 /mnt/cryptocur-data/ethereum 디렉토리에 저장됩니다
```

**요구사항:**
- 최소: 1TB 이상의 여유 공간
- 권장: 2TB 이상의 SSD

#### 메모리(RAM) 확인
```bash
# 메모리 정보 확인
free -h

# 상세 메모리 정보
cat /proc/meminfo | grep MemTotal
```

**요구사항:**
- 최소: 8GB RAM
- 권장: 16GB 이상 RAM
- cache 설정 시 충분한 RAM 필요 (권장: 4-8GB)

#### CPU 확인
```bash
# CPU 정보 확인
lscpu

# CPU 코어 수 확인
nproc

# CPU 사용률 확인
top
# 또는
htop
```

**요구사항:**
- 최소: 4코어
- 권장: 8코어 이상

### 2. 네트워크 확인

#### 인터넷 연결 확인
```bash
# 인터넷 연결 테스트
ping -c 4 8.8.8.8

# DNS 확인
nslookup geth.ethereum.org

# 네트워크 속도 확인 (speedtest-cli 설치 필요)
# sudo apt-get install speedtest-cli
speedtest-cli
```

**요구사항:**
- 최소: 100Mbps 다운로드 속도
- 권장: 500Mbps 이상
- 안정적인 연결 필수 (월간 데이터 전송량: 수백 GB)

#### 포트 확인
```bash
# 포트 30303 (P2P) 사용 여부 확인
sudo netstat -tlnp | grep 30303
# 또는
sudo ss -tlnp | grep 30303

# 포트 8545 (HTTP-RPC) 사용 여부 확인
sudo netstat -tlnp | grep 8545
# 또는
sudo ss -tlnp | grep 8545

# 포트 8546 (WebSocket-RPC) 사용 여부 확인
sudo netstat -tlnp | grep 8546
# 또는
sudo ss -tlnp | grep 8546

# 포트가 사용 중이면 다른 프로세스 확인
sudo lsof -i :30303
sudo lsof -i :8545
sudo lsof -i :8546
```

**필요한 포트:**
- 30303: P2P 네트워크 통신 (인바운드/아웃바운드, TCP/UDP)
- 8545: HTTP-RPC 서버 (로컬호스트만 권장)
- 8546: WebSocket-RPC 서버 (로컬호스트만 권장)

#### 방화벽 설정 확인
```bash
# UFW 방화벽 상태 확인
sudo ufw status

# 방화벽이 활성화되어 있다면 포트 열기
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp

# RPC 포트는 외부에 노출하지 않는 것이 좋음
# 로컬호스트만 사용하는 경우 포트 열기 불필요
```

### 3. Docker 설치 확인

#### Docker 설치 여부 확인
```bash
# Docker 버전 확인
docker --version

# Docker Compose 버전 확인
docker-compose --version

# Docker 서비스 상태 확인
sudo systemctl status docker
```

#### Docker가 설치되어 있지 않은 경우
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io docker-compose

# Docker 서비스 시작
sudo systemctl start docker
sudo systemctl enable docker

# 현재 사용자를 docker 그룹에 추가 (sudo 없이 사용하기 위해)
sudo usermod -aG docker $USER

# 그룹 변경 적용 (로그아웃 후 재로그인 필요)
newgrp docker

# Docker 설치 확인
docker run hello-world
```

---

## Docker 설치 및 설정

Docker 및 Docker Compose 설치 방법은 Bitcoin 가이드와 동일합니다. [Bitcoin Docker 설치 가이드](../bitcoin/docker/docker-setup-and-operations.md#docker-설치-및-설정)를 참고하세요.

---

## Ethereum 노드 Docker 설치

### 1. 프로젝트 디렉토리 준비

```bash
# 작업 디렉토리로 이동
cd /path/to/blockchain-node-guides/chains/ethereum/docker

# 현재 디렉토리 확인
pwd
```

### 2. 데이터 디렉토리 준비

```bash
# Ethereum 데이터를 저장할 디렉토리 생성
sudo mkdir -p /mnt/cryptocur-data/ethereum

# 방법 1: 컨테이너 내부 ethereum 사용자 UID 확인 후 설정 (권장)
# 먼저 임시로 컨테이너를 실행하여 ethereum 사용자 UID 확인
docker run --rm docker_geth id -u ethereum
# 출력 예시: 1000 (이 값을 기록)

# 확인된 UID로 디렉토리 소유자 변경
ETHEREUM_UID=$(docker run --rm docker_geth id -u ethereum)
sudo chown -R $ETHEREUM_UID:$ETHEREUM_UID /mnt/cryptocur-data/ethereum
sudo chmod -R 755 /mnt/cryptocur-data/ethereum

# 방법 2: 일반적으로 ethereum 사용자는 UID 1000 (첫 번째 일반 사용자)
# sudo chown -R 1000:1000 /mnt/cryptocur-data/ethereum
# sudo chmod -R 755 /mnt/cryptocur-data/ethereum

# 디스크 공간 확인
df -h /mnt/cryptocur-data

# 권한 확인
ls -ld /mnt/cryptocur-data/ethereum
```

**참고:** `/mnt/cryptocur-data/ethereum` 디렉토리는 Ethereum 블록체인 데이터를 저장하는 위치입니다. 충분한 디스크 공간(최소 1TB 이상)이 있는지 확인하세요.

### 3. 설정 파일 준비

```bash
# 설정 파일 예제 복사
cp geth.toml.example geth.toml

# 설정 파일 편집 (선택사항)
nano geth.toml
# 또는
vi geth.toml
```

**주요 설정 항목:**
```toml
# 네트워크 설정
# mainnet = true  # 메인넷

# HTTP-RPC 설정
[HTTP]
Enabled = true
Addr = "0.0.0.0"
Port = 8545
APIs = ["eth", "net", "web3", "admin", "debug"]

# WebSocket-RPC 설정
[WS]
Enabled = true
Addr = "0.0.0.0"
Port = 8546
APIs = ["eth", "net", "web3", "admin", "debug"]

# 성능 최적화
Cache = 4096          # 캐시 크기 (MB)
SyncMode = "snap"     # 동기화 모드
MaxPeers = 50         # 최대 피어 수
```

### 4. Docker Compose로 노드 실행

```bash
# 이미지 빌드 및 컨테이너 시작 (백그라운드)
docker-compose up -d

# 빌드 과정 확인
docker-compose logs -f

# 컨테이너 상태 확인
docker-compose ps
```

### 5. 초기 동기화 확인

```bash
# 로그 실시간 확인
docker-compose logs -f geth

# 동기화 상태 확인 (아래 "노드 상태 확인" 섹션 참고)
docker-compose exec geth geth attach --exec 'eth.syncing'
```

**참고:** 초기 동기화는 수일이 소요될 수 있습니다. 진행 상황은 로그에서 확인할 수 있습니다.

---

## 노드 상태 확인

### 1. 컨테이너 상태 확인

```bash
# 컨테이너 실행 상태 확인
docker-compose ps

# 상세 정보 확인
docker ps | grep ethereum

# 컨테이너 리소스 사용량 확인
docker stats ethereum-node

# 컨테이너 로그 확인
docker-compose logs -f geth
# 또는 최근 100줄만
docker-compose logs --tail=100 geth
```

### 2. 블록체인 동기화 상태 확인

```bash
# 동기화 상태 조회
docker-compose exec geth geth attach --exec 'eth.syncing'

# 동기화 중이면 false, 완료되면 false 반환
# 동기화 중일 때는 현재 블록과 최신 블록 정보 반환

# 최신 블록 번호 확인
docker-compose exec geth geth attach --exec 'eth.blockNumber'

# 체인 ID 확인
docker-compose exec geth geth attach --exec 'net.version'
```

**동기화 완료 확인:**
```bash
# 동기화 상태 확인
SYNCING=$(docker-compose exec -T geth geth attach --exec 'eth.syncing')
if [ "$SYNCING" = "false" ]; then
    echo "동기화 완료"
else
    echo "동기화 중: $SYNCING"
fi
```

### 3. 네트워크 연결 상태 확인

```bash
# 피어 연결 수 확인
docker-compose exec geth geth attach --exec 'net.peerCount'

# 피어 연결 상세 정보
docker-compose exec geth geth attach --exec 'admin.peers'

# 네트워크 정보
docker-compose exec geth geth attach --exec 'admin.nodeInfo'
```

### 4. 노드 상태 종합 확인

```bash
# 노드가 정상 작동 중인지 확인
docker-compose exec geth geth attach --exec 'net.listening'

# 최신 블록 정보
docker-compose exec geth geth attach --exec 'eth.blockNumber'

# 체인 상태 요약
docker-compose exec geth geth attach --exec 'eth.getBlock("latest")'
```

---

## 노드 정보 조회

### 1. 블록체인 정보 조회

#### 기본 블록체인 정보
```bash
# 최신 블록 번호
docker-compose exec geth geth attach --exec 'eth.blockNumber'

# 특정 블록 정보
docker-compose exec geth geth attach --exec 'eth.getBlock(eth.blockNumber)'

# 체인 ID
docker-compose exec geth geth attach --exec 'net.version'

# 네트워크 ID
docker-compose exec geth geth attach --exec 'net.version'
```

### 2. 트랜잭션 정보 조회

#### 트랜잭션 조회
```bash
# 트랜잭션 정보 조회 (트랜잭션 해시로)
docker-compose exec geth geth attach --exec 'eth.getTransaction("트랜잭션해시")'

# 트랜잭션 영수증 조회
docker-compose exec geth geth attach --exec 'eth.getTransactionReceipt("트랜잭션해시")'
```

#### 메모리 풀 정보
```bash
# 대기 중인 트랜잭션 수
docker-compose exec geth geth attach --exec 'txpool.status'

# 대기 중인 트랜잭션 상세 정보
docker-compose exec geth geth attach --exec 'txpool.content'
```

### 3. 네트워크 정보 조회

```bash
# 피어 정보
docker-compose exec geth geth attach --exec 'admin.peers'

# 네트워크 정보
docker-compose exec geth geth attach --exec 'admin.nodeInfo'

# 연결된 피어 수
docker-compose exec geth geth attach --exec 'net.peerCount'
```

---

## 트랜잭션 브로드캐스팅

### 1. 트랜잭션 생성 및 브로드캐스팅

#### Geth Console 사용

```bash
# Geth 콘솔 접속
docker-compose exec geth geth attach

# 콘솔 내에서:
# 1. 계정 생성 (또는 기존 계정 사용)
personal.newAccount("password")

# 2. 계정 잠금 해제
personal.unlockAccount(eth.accounts[0], "password", 0)

# 3. 트랜잭션 생성 및 전송
eth.sendTransaction({
    from: eth.accounts[0],
    to: "0x받는주소",
    value: web3.toWei(0.1, "ether")
})
```

#### Web3.js 또는 다른 라이브러리 사용

```bash
# HTTP-RPC를 통해 트랜잭션 전송
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_sendTransaction",
    "params":[{
        "from":"0x보내는주소",
        "to":"0x받는주소",
        "value":"0xde0b6b3a7640000"
    }],
    "id":1
  }' \
  http://localhost:8545
```

### 2. 트랜잭션 상태 확인

```bash
# 트랜잭션 해시로 상태 확인
docker-compose exec geth geth attach --exec 'eth.getTransaction("트랜잭션해시")'

# 트랜잭션 영수증 확인 (확인된 경우)
docker-compose exec geth geth attach --exec 'eth.getTransactionReceipt("트랜잭션해시")'

# 트랜잭션이 포함된 블록 확인
docker-compose exec geth geth attach --exec 'eth.getTransaction("트랜잭션해시").blockNumber'
```

---

## 문제 해결

### 1. 컨테이너가 시작되지 않음

```bash
# 로그 확인
docker-compose logs geth

# 컨테이너 상태 확인
docker-compose ps -a

# 컨테이너 재시작
docker-compose restart geth

# 컨테이너 재생성
docker-compose up -d --force-recreate geth
```

### 2. "executable file not found" 에러

Bitcoin 가이드의 [동일한 문제 해결 방법](../bitcoin/docker/docker-setup-and-operations.md#2-executable-file-not-found-또는-unable-to-start-container-process-에러)을 참고하세요.

### 3. 권한 문제 (Settings file could not be written)

```bash
# 컨테이너 중지
docker-compose down

# 디렉토리 권한 설정
sudo mkdir -p /mnt/cryptocur-data/ethereum
ETHEREUM_UID=$(docker run --rm docker_geth id -u ethereum)
sudo chown -R $ETHEREUM_UID:$ETHEREUM_UID /mnt/cryptocur-data/ethereum
sudo chmod -R 755 /mnt/cryptocur-data/ethereum

# 컨테이너 재시작
docker-compose up -d
```

### 4. 동기화가 느림

```bash
# 연결된 피어 수 확인
docker-compose exec geth geth attach --exec 'net.peerCount'

# 피어 정보 확인
docker-compose exec geth geth attach --exec 'admin.peers'

# 캐시 증가 (geth.toml 수정 후 재시작)
# Cache = 8192
```

### 5. 디스크 공간 부족

```bash
# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/ethereum

# 디렉토리별 크기 확인
du -h --max-depth=1 /mnt/cryptocur-data/ethereum | sort -hr

# 불필요한 로그 파일 삭제
docker-compose exec geth find /home/ethereum/.ethereum -name "*.log" -delete

# 또는 호스트에서 직접 삭제
find /mnt/cryptocur-data/ethereum -name "*.log" -delete
```

### 6. RPC 연결 실패

```bash
# RPC 설정 확인
docker-compose exec geth cat /home/ethereum/.ethereum/geth.toml | grep -A 5 HTTP

# RPC 테스트
docker-compose exec geth geth attach --exec 'net.version'

# RPC 포트 확인
docker-compose exec geth netstat -tlnp | grep 8545
```

---

## 추가 리소스

- [Geth 공식 문서](https://geth.ethereum.org/docs)
- [Geth RPC API 문서](https://geth.ethereum.org/docs/rpc/server)
- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Compose 문서](https://docs.docker.com/compose/)

---

## 요약

이 가이드는 다음을 다룹니다:

1. ✅ **설치 전 시스템 확인**: 하드웨어, 네트워크, 포트, Docker 확인
2. ✅ **Docker 설치 및 설정**: Docker 및 Docker Compose 설치
3. ✅ **Ethereum 노드 설치**: Docker Compose를 사용한 노드 설치
4. ✅ **노드 상태 확인**: 동기화 상태, 네트워크 연결, 컨테이너 상태 확인
5. ✅ **정보 조회**: 블록체인, 트랜잭션, 네트워크 정보 조회
6. ✅ **트랜잭션 브로드캐스팅**: 트랜잭션 생성 및 브로드캐스팅 방법

이 가이드를 따라하면 Linux 서버에서 Ethereum 노드를 성공적으로 설치하고 운영할 수 있습니다.
