# Ethereum 노드 Docker 설치 및 운영 가이드

Linux 서버에서 Ethereum 노드를 Docker로 설치하고 운영하는 종합 가이드입니다.

## Ethereum 노드 구성

이 Docker 설정은 **Execution Layer (Geth)**와 **Consensus Layer (Prysm)**를 통합한 완전한 Ethereum 노드입니다.

### Execution Layer (실행 레이어) - Geth
- **공식 릴리스**: [https://github.com/ethereum/go-ethereum/releases](https://github.com/ethereum/go-ethereum/releases)
- **버전**: v1.16.7-b9f3a3d9 (geth-alltools)
- **역할**: 트랜잭션 실행, 상태 관리, 블록 생성
- **포트**: 30303 (P2P), 3001 (Engine API), 3002 (HTTP-RPC)

### Consensus Layer (합의 레이어) - Prysm
- **공식 릴리스**: [https://github.com/prysmaticlabs/prysm/releases](https://github.com/prysmaticlabs/prysm/releases)
- **버전**: v7.1.2
- **역할**: 블록 검증, 합의, 검증자 운영
- **포트**: 13000 (P2P), 4000 (gRPC), 3500 (HTTP-RPC)

### 통합 실행
- `launcher.sh` 스크립트가 Geth와 Prysm을 자동으로 실행
- JWT secret 자동 생성 및 공유
- Geth가 준비될 때까지 대기 후 Prysm 시작

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
- 8551: Engine API 서버 (Consensus Layer와 통신, 로컬호스트만 권장)

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

# 권한 설정 (cryptocurrency 사용자는 일반적으로 UID 1000)
sudo chown -R 1000:1000 /mnt/cryptocur-data/ethereum
sudo chmod -R 755 /mnt/cryptocur-data/ethereum

# 디스크 공간 확인
df -h /mnt/cryptocur-data

# 권한 확인
ls -ld /mnt/cryptocur-data/ethereum
```

**참고:** `/mnt/cryptocur-data/ethereum` 디렉토리는 Ethereum 블록체인 데이터를 저장하는 위치입니다. 충분한 디스크 공간(최소 1TB 이상)이 있는지 확인하세요.

### 3. 환경 변수 설정 (선택사항)

```bash
# .env 파일 생성 (선택사항)
cat > .env << EOF
# 네트워크 모드: mainnet (기본값), goerli, sepolia
MODE=mainnet

# Geth P2P 포트
P2PPORT=30303

# 최대 피어 연결 수
MAXPEERS=25
EOF
```

**참고:** JWT secret은 Dockerfile에서 자동으로 생성되므로 별도로 생성할 필요가 없습니다.

**주요 특징:**
- Geth와 Prysm이 통합된 단일 컨테이너
- launcher.sh 스크립트가 자동으로 두 레이어를 실행
- JWT secret 자동 생성 및 공유
- 환경 변수로 네트워크 모드 설정 (mainnet, goerli, sepolia)
- Geth가 준비될 때까지 대기 후 Prysm 시작

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
docker-compose logs -f ethereum

# Geth 동기화 상태 확인
docker-compose exec ethereum ./geth attach --exec 'eth.syncing'

# Prysm 동기화 상태 확인
curl http://localhost:3500/eth/v1/node/syncing
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
docker-compose logs -f ethereum
# 또는 최근 100줄만
docker-compose logs --tail=100 ethereum

# Geth 로그만 확인
docker-compose logs -f ethereum | grep -i geth

# Prysm 로그만 확인
docker-compose logs -f ethereum | grep -i prysm
```

### 2. 블록체인 동기화 상태 확인

#### Geth (Execution Layer) 동기화 상태

```bash
# 동기화 상태 조회
docker-compose exec ethereum ./geth attach --exec 'eth.syncing'

# 동기화 중이면 false, 완료되면 false 반환
# 동기화 중일 때는 현재 블록과 최신 블록 정보 반환

# 최신 블록 번호 확인
docker-compose exec ethereum ./geth attach --exec 'eth.blockNumber'

# 체인 ID 확인
docker-compose exec ethereum ./geth attach --exec 'net.version'

# 피어 연결 수 확인
docker-compose exec ethereum ./geth attach --exec 'net.peerCount'
```

**Geth 동기화 완료 확인:**
```bash
# 동기화 상태 확인
SYNCING=$(docker-compose exec -T ethereum ./geth attach --exec 'eth.syncing')
if [ "$SYNCING" = "false" ]; then
    echo "Geth 동기화 완료"
else
    echo "Geth 동기화 중: $SYNCING"
fi
```

#### Prysm (Consensus Layer) 동기화 상태

```bash
# 동기화 상태 확인
curl http://localhost:3500/eth/v1/node/syncing

# 피어 정보 확인
curl http://localhost:3500/eth/v1/node/peers

# 노드 정보 확인
curl http://localhost:3500/eth/v1/node/identity

# 최신 블록 확인
curl http://localhost:3500/eth/v1/beacon/blocks/head
```

### 3. 네트워크 연결 상태 확인

#### Geth 네트워크 정보

```bash
# 피어 연결 수 확인
docker-compose exec ethereum ./geth attach --exec 'net.peerCount'

# 피어 연결 상세 정보
docker-compose exec ethereum ./geth attach --exec 'admin.peers'

# 네트워크 정보
docker-compose exec ethereum ./geth attach --exec 'admin.nodeInfo'
```

#### Prysm 네트워크 정보

```bash
# 피어 정보 확인
curl http://localhost:3500/eth/v1/node/peers

# 피어 수 확인
curl http://localhost:3500/eth/v1/node/peers | jq '.data | length'

# 노드 정보
curl http://localhost:3500/eth/v1/node/identity
```

### 4. 노드 상태 종합 확인

```bash
# Geth 상태 확인
docker-compose exec ethereum ./geth attach --exec 'net.listening'
docker-compose exec ethereum ./geth attach --exec 'eth.blockNumber'

# Prysm 상태 확인
curl http://localhost:3500/eth/v1/node/syncing
curl http://localhost:3500/eth/v1/node/health

# 통합 상태 확인 스크립트
echo "=== Geth Status ==="
docker-compose exec ethereum ./geth attach --exec 'eth.blockNumber'
docker-compose exec ethereum ./geth attach --exec 'net.peerCount'
echo ""
echo "=== Prysm Status ==="
curl -s http://localhost:3500/eth/v1/node/syncing | jq '.'
curl -s http://localhost:3500/eth/v1/node/peers | jq '.data | length' | xargs echo "Peers:"
```

---

## 노드 정보 조회

### 1. 블록체인 정보 조회

#### Geth (Execution Layer) 정보

```bash
# 최신 블록 번호
docker-compose exec ethereum ./geth attach --exec 'eth.blockNumber'

# 특정 블록 정보
docker-compose exec ethereum ./geth attach --exec 'eth.getBlock(eth.blockNumber)'

# 체인 ID
docker-compose exec ethereum ./geth attach --exec 'net.version'

# 네트워크 ID
docker-compose exec ethereum ./geth attach --exec 'net.version'
```

#### Prysm (Consensus Layer) 정보

```bash
# 최신 블록 정보
curl http://localhost:3500/eth/v1/beacon/blocks/head

# 최신 상태 정보
curl http://localhost:3500/eth/v1/beacon/states/head

# 체인 스펙 정보
curl http://localhost:3500/eth/v1/config/spec
```

### 2. 트랜잭션 정보 조회

#### 트랜잭션 조회
```bash
# 트랜잭션 정보 조회 (트랜잭션 해시로)
docker-compose exec ethereum ./geth attach --exec 'eth.getTransaction("트랜잭션해시")'

# 트랜잭션 영수증 조회
docker-compose exec ethereum ./geth attach --exec 'eth.getTransactionReceipt("트랜잭션해시")'
```

#### 메모리 풀 정보
```bash
# 대기 중인 트랜잭션 수
docker-compose exec ethereum ./geth attach --exec 'txpool.status'

# 대기 중인 트랜잭션 상세 정보
docker-compose exec ethereum ./geth attach --exec 'txpool.content'
```

### 3. 네트워크 정보 조회

#### Geth 네트워크 정보
```bash
# 피어 정보
docker-compose exec ethereum ./geth attach --exec 'admin.peers'

# 네트워크 정보
docker-compose exec ethereum ./geth attach --exec 'admin.nodeInfo'

# 연결된 피어 수
docker-compose exec ethereum ./geth attach --exec 'net.peerCount'
```

#### Prysm 네트워크 정보
```bash
# 피어 정보
curl http://localhost:3500/eth/v1/node/peers

# 노드 정보
curl http://localhost:3500/eth/v1/node/identity
```

---

## 트랜잭션 브로드캐스팅

### 1. 트랜잭션 생성 및 브로드캐스팅

#### Geth Console 사용

```bash
# Geth 콘솔 접속
docker-compose exec ethereum ./geth attach

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

#### HTTP-RPC를 통한 트랜잭션 전송

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
  http://localhost:3002
```

### 2. 트랜잭션 상태 확인

```bash
# 트랜잭션 해시로 상태 확인
docker-compose exec ethereum ./geth attach --exec 'eth.getTransaction("트랜잭션해시")'

# 트랜잭션 영수증 확인 (확인된 경우)
docker-compose exec ethereum ./geth attach --exec 'eth.getTransactionReceipt("트랜잭션해시")'

# 트랜잭션이 포함된 블록 확인
docker-compose exec ethereum ./geth attach --exec 'eth.getTransaction("트랜잭션해시").blockNumber'
```

---

## 문제 해결

### 1. 컨테이너가 시작되지 않음

```bash
# 로그 확인
docker-compose logs ethereum

# 컨테이너 상태 확인
docker-compose ps -a

# 컨테이너 재시작
docker-compose restart ethereum

# 컨테이너 재생성
docker-compose up -d --force-recreate ethereum
```

### 2. "executable file not found" 에러

Bitcoin 가이드의 [동일한 문제 해결 방법](../bitcoin/docker/docker-setup-and-operations.md#2-executable-file-not-found-또는-unable-to-start-container-process-에러)을 참고하세요.

### 3. 권한 문제 (Settings file could not be written)

```bash
# 컨테이너 중지
docker-compose down

# 디렉토리 권한 설정
sudo mkdir -p /mnt/cryptocur-data/ethereum
sudo chown -R 1000:1000 /mnt/cryptocur-data/ethereum
sudo chmod -R 755 /mnt/cryptocur-data/ethereum

# 컨테이너 재시작
docker-compose up -d
```

### 4. 동기화가 느림

```bash
# Geth 피어 연결 수 확인
docker-compose exec ethereum ./geth attach --exec 'net.peerCount'

# Geth 피어 정보 확인
docker-compose exec ethereum ./geth attach --exec 'admin.peers'

# Prysm 피어 정보 확인
curl http://localhost:3500/eth/v1/node/peers

# MAXPEERS 환경 변수 증가 (docker-compose.yml 수정 후 재시작)
# MAXPEERS=50
```

### 5. 디스크 공간 부족

```bash
# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/ethereum

# 디렉토리별 크기 확인
du -h --max-depth=1 /mnt/cryptocur-data/ethereum | sort -hr

# 불필요한 로그 파일 삭제
docker-compose exec ethereum find /var/lib/coindata -name "*.log" -delete

# 또는 호스트에서 직접 삭제
find /mnt/cryptocur-data/ethereum -name "*.log" -delete
```

### 6. RPC 연결 실패

```bash
# Geth HTTP-RPC 테스트
docker-compose exec ethereum ./geth attach --exec 'net.version'

# Geth HTTP-RPC 포트 확인
docker-compose exec ethereum netstat -tlnp | grep 3002

# Geth Engine API 테스트
curl -X POST http://localhost:3001 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Prysm HTTP-RPC 테스트
curl http://localhost:3500/eth/v1/node/syncing

# Prysm HTTP-RPC 포트 확인
docker-compose exec ethereum netstat -tlnp | grep 3500
```

### 7. Docker 빌드 실패 (404 에러)

**증상:**
```
ERROR 404: The specified blob does not exist.
```

**원인:**
- Geth 다운로드 URL이 잘못되었거나 파일명이 변경됨
- GitHub 릴리스의 실제 파일명 형식이 예상과 다름 (커밋 해시 포함 등)

**해결 방법:**

1. **GitHub 릴리스 페이지에서 실제 파일명 확인**:
   - [https://github.com/ethereum/go-ethereum/releases](https://github.com/ethereum/go-ethereum/releases) 방문
   - 해당 버전의 Assets 섹션에서 실제 파일명 확인

2. **Dockerfile 수정**:
   ```dockerfile
   # 실제 파일명에 맞게 수정
   # 예: geth-linux-amd64-1.16.7-b9f3a3d.tar.gz (커밋 해시 포함)
   RUN GETH_COMMIT="b9f3a3d" && \
       GETH_TARBALL="geth-linux-amd64-${GETH_VERSION}-${GETH_COMMIT}.tar.gz" && \
       wget https://github.com/ethereum/go-ethereum/releases/download/v${GETH_VERSION}/${GETH_TARBALL}
   ```

3. **대안: 공식 다운로드 페이지 사용**:
   ```dockerfile
   # 공식 다운로드 페이지에서 다운로드
   RUN wget https://geth.ethereum.org/downloads/geth-linux-amd64-${GETH_VERSION}.tar.gz
   ```

4. **수동 다운로드 후 빌드**:
   ```bash
   # 호스트에서 수동으로 다운로드
   wget https://github.com/ethereum/go-ethereum/releases/download/v1.16.7/geth-linux-amd64-1.16.7-b9f3a3d.tar.gz
   
   # Dockerfile에서 로컬 파일 사용하도록 수정
   COPY geth-linux-amd64-1.16.7-b9f3a3d.tar.gz /tmp/
   RUN tar -xzf /tmp/geth-linux-amd64-1.16.7-b9f3a3d.tar.gz && \
       install -m 0755 -o root -g root geth /usr/local/bin/
   ```

**참고**: 현재 Dockerfile은 여러 URL을 시도하는 fallback 방식을 사용하므로 대부분의 경우 자동으로 해결됩니다.

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
3. ✅ **Ethereum 통합 노드 설치**: Geth (Execution Layer) + Prysm (Consensus Layer) 통합 설치
4. ✅ **노드 상태 확인**: Geth와 Prysm 동기화 상태, 네트워크 연결, 컨테이너 상태 확인
5. ✅ **정보 조회**: 블록체인, 트랜잭션, 네트워크 정보 조회 (Geth 및 Prysm)
6. ✅ **트랜잭션 브로드캐스팅**: 트랜잭션 생성 및 브로드캐스팅 방법

### 주요 특징

- **통합 노드**: Geth와 Prysm이 하나의 컨테이너에서 실행
- **자동 실행**: launcher.sh 스크립트가 두 레이어를 자동으로 실행
- **JWT 자동 생성**: JWT secret이 자동으로 생성되어 두 레이어 간 통신
- **환경 변수 기반**: 네트워크 모드와 설정을 환경 변수로 제어
- **안전한 종료**: SIGTERM/SIGINT 신호를 받으면 두 프로세스를 안전하게 종료

이 가이드를 따라하면 Linux 서버에서 완전한 Ethereum 노드(Geth + Prysm)를 성공적으로 설치하고 운영할 수 있습니다.
