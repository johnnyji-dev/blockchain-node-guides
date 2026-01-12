# Bitcoin 노드 Docker 설치 및 운영 가이드

Linux 서버에서 Bitcoin 노드를 Docker로 설치하고 운영하는 종합 가이드입니다.

## 목차
- [설치 전 시스템 확인](#설치-전-시스템-확인)
- [Docker 설치 및 설정](#docker-설치-및-설정)
- [Bitcoin 노드 Docker 설치](#bitcoin-노드-docker-설치)
- [노드 상태 확인](#노드-상태-확인)
- [노드 정보 조회](#노드-정보-조회)
- [트랜잭션 브로드캐스팅](#트랜잭션-브로드캐스팅)
- [문제 해결](#문제-해결)

---

## 설치 전 시스템 확인

Bitcoin 노드를 설치하기 전에 시스템이 요구사항을 만족하는지 확인해야 합니다.

### 1. 하드웨어 요구사항 확인

#### 디스크 공간 확인
```bash
# 전체 디스크 사용량 확인
df -h

# Bitcoin 데이터 저장 디렉토리 용량 확인
df -h /mnt/cryptocur-data

# Bitcoin 블록체인 데이터는 약 500GB 이상 필요 (2024년 기준)
# SSD 사용을 강력히 권장 (HDD는 동기화가 매우 느림)
# 데이터는 /mnt/cryptocur-data/bitcoin 디렉토리에 저장됩니다
```

**요구사항:**
- 최소: 500GB 이상의 여유 공간
- 권장: 1TB 이상의 SSD
- txindex 활성화 시: 추가 20GB 이상

#### 메모리(RAM) 확인
```bash
# 메모리 정보 확인
free -h

# 상세 메모리 정보
cat /proc/meminfo | grep MemTotal
```

**요구사항:**
- 최소: 4GB RAM
- 권장: 8GB 이상 RAM
- dbcache 설정 시 충분한 RAM 필요 (권장: 4-8GB)

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
- 최소: 2코어
- 권장: 4코어 이상

### 2. 네트워크 확인

#### 인터넷 연결 확인
```bash
# 인터넷 연결 테스트
ping -c 4 8.8.8.8

# DNS 확인
nslookup bitcoincore.org

# 네트워크 속도 확인 (speedtest-cli 설치 필요)
# sudo apt-get install speedtest-cli
speedtest-cli
```

**요구사항:**
- 최소: 50Mbps 다운로드 속도
- 권장: 100Mbps 이상
- 안정적인 연결 필수 (월간 데이터 전송량: 수백 GB)

#### 포트 확인
```bash
# 포트 8333 (P2P) 사용 여부 확인
sudo netstat -tlnp | grep 8333
# 또는
sudo ss -tlnp | grep 8333

# 포트 8332 (RPC) 사용 여부 확인
sudo netstat -tlnp | grep 8332
# 또는
sudo ss -tlnp | grep 8332

# 포트가 사용 중이면 다른 프로세스 확인
sudo lsof -i :8333
sudo lsof -i :8332
```

**필요한 포트:**
- 8333: P2P 네트워크 통신 (인바운드/아웃바운드)
- 8332: RPC 서버 (로컬호스트만 권장)

#### 방화벽 설정 확인
```bash
# UFW 방화벽 상태 확인
sudo ufw status

# 방화벽이 활성화되어 있다면 포트 열기
sudo ufw allow 8333/tcp
sudo ufw allow 8333/udp

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

### 4. 시스템 리소스 모니터링 도구 설치 (선택사항)

```bash
# htop 설치 (고급 프로세스 모니터)
sudo apt-get install -y htop

# iotop 설치 (I/O 모니터링)
sudo apt-get install -y iotop

# nethogs 설치 (네트워크 사용량 모니터링)
sudo apt-get install -y nethogs
```

### 5. 종합 확인 스크립트

다음 스크립트를 실행하여 모든 요구사항을 한 번에 확인할 수 있습니다:

```bash
#!/bin/bash
echo "=== Bitcoin 노드 설치 전 시스템 확인 ==="
echo ""

echo "1. 디스크 공간:"
df -h / | tail -1
echo ""

echo "2. 메모리:"
free -h
echo ""

echo "3. CPU 코어 수:"
nproc
echo ""

echo "4. 네트워크 연결:"
ping -c 2 8.8.8.8 > /dev/null 2>&1 && echo "✓ 인터넷 연결 정상" || echo "✗ 인터넷 연결 실패"
echo ""

echo "5. 포트 확인:"
if sudo netstat -tlnp 2>/dev/null | grep -q ":8333"; then
    echo "✗ 포트 8333이 이미 사용 중입니다"
else
    echo "✓ 포트 8333 사용 가능"
fi

if sudo netstat -tlnp 2>/dev/null | grep -q ":8332"; then
    echo "✗ 포트 8332가 이미 사용 중입니다"
else
    echo "✓ 포트 8332 사용 가능"
fi
echo ""

echo "6. Docker 확인:"
if command -v docker &> /dev/null; then
    echo "✓ Docker 설치됨: $(docker --version)"
else
    echo "✗ Docker가 설치되어 있지 않습니다"
fi

if command -v docker-compose &> /dev/null; then
    echo "✓ Docker Compose 설치됨: $(docker-compose --version)"
else
    echo "✗ Docker Compose가 설치되어 있지 않습니다"
fi
echo ""

echo "=== 확인 완료 ==="
```

---

## Docker 설치 및 설정

### Docker 및 Docker Compose 설치

#### Ubuntu/Debian
```bash
# 기존 Docker 제거 (있는 경우)
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# 필수 패키지 설치
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker 공식 GPG 키 추가
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker 저장소 추가
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 설치
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 서비스 시작 및 자동 시작 설정
sudo systemctl start docker
sudo systemctl enable docker

# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER

# 그룹 변경 적용
newgrp docker

# 설치 확인
docker --version
docker compose version
```

### Docker 설정 최적화

#### Docker 데이터 디렉토리 변경 (선택사항)
큰 볼륨을 사용하는 경우 별도의 디스크에 Docker 데이터를 저장하는 것이 좋습니다:

```bash
# /etc/docker/daemon.json 파일 생성/수정
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "data-root": "/mnt/docker-data"
}
EOF

# 디렉토리 생성 및 권한 설정
sudo mkdir -p /mnt/docker-data
sudo chown root:root /mnt/docker-data

# Docker 재시작
sudo systemctl restart docker
```

---

## Bitcoin 노드 Docker 설치

### 1. 프로젝트 디렉토리 준비

```bash
# 작업 디렉토리로 이동
cd /path/to/blockchain-node-guides/chains/bitcoin/docker

# 현재 디렉토리 확인
pwd
```

### 2. 데이터 디렉토리 준비

```bash
# Bitcoin 데이터를 저장할 디렉토리 생성
sudo mkdir -p /mnt/cryptocur-data/bitcoin

# 디렉토리 권한 설정 (Docker가 접근할 수 있도록)
# Docker는 보통 root로 실행되므로, 필요시 권한 조정
sudo chown -R $USER:$USER /mnt/cryptocur-data/bitcoin
# 또는 Docker 그룹에 권한 부여
sudo chmod -R 755 /mnt/cryptocur-data/bitcoin

# 디스크 공간 확인
df -h /mnt/cryptocur-data
```

**참고:** `/mnt/cryptocur-data/bitcoin` 디렉토리는 Bitcoin 블록체인 데이터를 저장하는 위치입니다. 충분한 디스크 공간(최소 500GB 이상)이 있는지 확인하세요.

### 3. 설정 파일 준비

```bash
# 설정 파일 예제 복사
cp bitcoin.conf.example bitcoin.conf

# 설정 파일 편집
nano bitcoin.conf
# 또는
vi bitcoin.conf
```

**필수 수정 사항:**
- `rpcpassword`: 강력한 비밀번호로 변경 (최소 32자 권장)
- 필요에 따라 다른 설정 조정

**주요 설정 항목:**
```conf
# RPC 설정 (필수)
server=1
rpcuser=bitcoin
rpcpassword=your_secure_password_here  # 반드시 변경!
rpcbind=0.0.0.0
rpcport=8332
rpcallowip=127.0.0.1

# 성능 최적화
txindex=1              # 트랜잭션 인덱스 (추가 디스크 공간 필요)
dbcache=4500          # 데이터베이스 캐시 (MB)
maxmempool=300        # 메모리 풀 크기 (MB)

# 네트워크 설정
port=8333             # P2P 포트
listen=1              # 인바운드 연결 허용
maxconnections=125    # 최대 연결 수
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
docker-compose logs -f bitcoind

# 동기화 상태 확인 (아래 "노드 상태 확인" 섹션 참고)
docker-compose exec bitcoind bitcoin-cli getblockchaininfo
```

**참고:** 초기 동기화는 수일이 소요될 수 있습니다. 진행 상황은 로그에서 확인할 수 있습니다.

---

## 노드 상태 확인

### 1. 컨테이너 상태 확인

```bash
# 컨테이너 실행 상태 확인
docker-compose ps

# 상세 정보 확인
docker ps | grep bitcoin

# 컨테이너 리소스 사용량 확인
docker stats bitcoin-node

# 컨테이너 로그 확인
docker-compose logs -f bitcoind
# 또는 최근 100줄만
docker-compose logs --tail=100 bitcoind
```

### 2. 블록체인 동기화 상태 확인

```bash
# 블록체인 정보 조회
docker-compose exec bitcoind bitcoin-cli getblockchaininfo

# 주요 필드 설명:
# - blocks: 현재 동기화된 블록 높이
# - headers: 다운로드된 헤더 수
# - verificationprogress: 동기화 진행률 (0.0 ~ 1.0)
# - chain: 네트워크 종류 (main, test, regtest)
```

**동기화 완료 확인:**
```bash
# 동기화 진행률 확인
docker-compose exec bitcoind bitcoin-cli getblockchaininfo | grep verificationprogress

# verificationprogress가 0.999 이상이면 거의 완료
# blocks와 headers가 같으면 동기화 완료
```

### 3. 네트워크 연결 상태 확인

```bash
# 네트워크 정보 조회
docker-compose exec bitcoind bitcoin-cli getnetworkinfo

# 연결된 피어 수 확인
docker-compose exec bitcoind bitcoin-cli getconnectioncount

# 피어 연결 상세 정보
docker-compose exec bitcoind bitcoin-cli getpeerinfo

# 네트워크 토폴로지 정보
docker-compose exec bitcoind bitcoin-cli getnettotals
```

### 4. 노드 상태 종합 확인

```bash
# 노드가 정상 작동 중인지 확인
docker-compose exec bitcoind bitcoin-cli uptime

# 최신 블록 정보
docker-compose exec bitcoind bitcoin-cli getblockcount

# 체인 상태 요약
docker-compose exec bitcoind bitcoin-cli getchaintxstats
```

### 5. 상태 확인 스크립트

다음 스크립트로 노드 상태를 한 번에 확인할 수 있습니다:

```bash
#!/bin/bash
echo "=== Bitcoin 노드 상태 확인 ==="
echo ""

echo "1. 컨테이너 상태:"
docker-compose ps
echo ""

echo "2. 블록체인 동기화:"
docker-compose exec bitcoind bitcoin-cli getblockchaininfo | grep -E "(blocks|headers|verificationprogress|chain)"
echo ""

echo "3. 네트워크 연결:"
docker-compose exec bitcoind bitcoin-cli getconnectioncount
echo ""

echo "4. 최신 블록:"
docker-compose exec bitcoind bitcoin-cli getblockcount
echo ""

echo "5. 노드 업타임:"
docker-compose exec bitcoind bitcoin-cli uptime
echo ""

echo "=== 확인 완료 ==="
```

---

## 노드 정보 조회

### 1. 블록체인 정보 조회

#### 기본 블록체인 정보
```bash
# 전체 블록체인 정보
docker-compose exec bitcoind bitcoin-cli getblockchaininfo

# 특정 필드만 조회
docker-compose exec bitcoind bitcoin-cli getblockchaininfo | jq '.blocks'
docker-compose exec bitcoind bitcoin-cli getblockchaininfo | jq '.chain'
docker-compose exec bitcoind bitcoin-cli getblockchaininfo | jq '.verificationprogress'
```

#### 블록 정보 조회
```bash
# 최신 블록 해시
docker-compose exec bitcoind bitcoin-cli getbestblockhash

# 특정 블록 정보 (블록 해시로)
docker-compose exec bitcoind bitcoin-cli getblock "블록해시"

# 특정 블록 정보 (블록 높이로)
docker-compose exec bitcoind bitcoin-cli getblockhash 800000
docker-compose exec bitcoind bitcoin-cli getblock $(bitcoin-cli getblockhash 800000)

# 최신 블록 정보
LATEST_HASH=$(docker-compose exec -T bitcoind bitcoin-cli getbestblockhash)
docker-compose exec bitcoind bitcoin-cli getblock "$LATEST_HASH"
```

### 2. 트랜잭션 정보 조회

#### 트랜잭션 조회 (txindex 필요)
```bash
# 트랜잭션 정보 조회 (txid로)
docker-compose exec bitcoind bitcoin-cli getrawtransaction "트랜잭션ID" true

# 트랜잭션 정보 조회 (JSON 형식)
docker-compose exec bitcoind bitcoin-cli getrawtransaction "트랜잭션ID" 1

# 트랜잭션 정보 조회 (16진수 원시 데이터)
docker-compose exec bitcoind bitcoin-cli getrawtransaction "트랜잭션ID" false
```

#### 메모리 풀 정보
```bash
# 메모리 풀의 트랜잭션 수
docker-compose exec bitcoind bitcoin-cli getmempoolinfo

# 메모리 풀의 모든 트랜잭션 ID
docker-compose exec bitcoind bitcoin-cli getrawmempool

# 특정 트랜잭션의 메모리 풀 정보
docker-compose exec bitcoind bitcoin-cli getmempoolentry "트랜잭션ID"
```

### 3. 네트워크 정보 조회

```bash
# 네트워크 정보 전체
docker-compose exec bitcoind bitcoin-cli getnetworkinfo

# 연결된 피어 정보
docker-compose exec bitcoind bitcoin-cli getpeerinfo

# 네트워크 통계
docker-compose exec bitcoind bitcoin-cli getnettotals

# 네트워크 활동 모니터링
docker-compose exec bitcoind bitcoin-cli getnetworkinfo | jq '.connections'
```

### 4. 마이닝 정보 조회 (테스트넷/Regtest)

```bash
# 마이닝 정보 (테스트넷 또는 regtest에서만 작동)
docker-compose exec bitcoind bitcoin-cli getmininginfo

# 블록 템플릿 (마이닝용)
docker-compose exec bitcoind bitcoin-cli getblocktemplate
```

### 5. 지갑 정보 조회 (지갑이 로드된 경우)

```bash
# 지갑 정보
docker-compose exec bitcoind bitcoin-cli getwalletinfo

# 잔액 확인
docker-compose exec bitcoind bitcoin-cli getbalance

# 거래 내역
docker-compose exec bitcoind bitcoin-cli listtransactions

# 주소 목록
docker-compose exec bitcoind bitcoin-cli listaddresses
```

### 6. 유용한 정보 조회 명령어 모음

```bash
# 노드 버전 정보
docker-compose exec bitcoind bitcoin-cli getnetworkinfo | jq '.version'

# 체인 통계
docker-compose exec bitcoind bitcoin-cli getchaintxstats

# 체인 상태
docker-compose exec bitcoind bitcoin-cli getchainstates

# 블록 서브사이디 정보
docker-compose exec bitcoind bitcoin-cli getblocksubsidy

# 추정된 블록 높이
docker-compose exec bitcoind bitcoin-cli getblockcount
```

---

## 트랜잭션 브로드캐스팅

### 1. 트랜잭션 생성

#### 원시 트랜잭션 생성 (수동)

트랜잭션을 브로드캐스팅하려면 먼저 유효한 원시 트랜잭션을 생성해야 합니다.

```bash
# 원시 트랜잭션 생성 (bitcoin-tx 사용)
# 주의: 실제 사용 시 올바른 입력과 출력을 설정해야 함

# 예시: 간단한 트랜잭션 구조 생성
docker-compose exec bitcoind bitcoin-tx -create

# 트랜잭션에 입력 추가
docker-compose exec bitcoind bitcoin-tx -create in=이전트랜잭션ID:인덱스

# 트랜잭션에 출력 추가
docker-compose exec bitcoind bitcoin-tx -create out=주소:금액
```

#### 지갑을 사용한 트랜잭션 생성 (권장)

지갑이 로드되어 있는 경우 더 쉽게 트랜잭션을 생성할 수 있습니다:

```bash
# 트랜잭션 전송 (지갑에서)
docker-compose exec bitcoind bitcoin-cli sendtoaddress "받는주소" 금액

# 예시: 0.001 BTC 전송
docker-compose exec bitcoind bitcoin-cli sendtoaddress "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh" 0.001

# 수수료 포함 트랜잭션 생성 (브로드캐스팅 전 확인)
docker-compose exec bitcoind bitcoin-cli sendtoaddress "받는주소" 금액 "" "" true

# 원시 트랜잭션 생성 (서명하지 않음)
docker-compose exec bitcoind bitcoin-cli createrawtransaction '[{"txid":"이전트랜잭션ID","vout":인덱스}]' '{"받는주소":금액}'

# 트랜잭션 서명
docker-compose exec bitcoind bitcoin-cli signrawtransactionwithwallet "원시트랜잭션hex"
```

### 2. 트랜잭션 브로드캐스팅

#### sendrawtransaction 사용 (권장)

```bash
# 서명된 원시 트랜잭션 브로드캐스팅
docker-compose exec bitcoind bitcoin-cli sendrawtransaction "서명된트랜잭션HEX"

# 예시:
# 1. 원시 트랜잭션 생성
RAW_TX=$(docker-compose exec -T bitcoind bitcoin-cli createrawtransaction '[{"txid":"이전TXID","vout":0}]' '{"받는주소":0.001}')

# 2. 트랜잭션 서명
SIGNED_TX=$(docker-compose exec -T bitcoind bitcoin-cli signrawtransactionwithwallet "$RAW_TX" | jq -r '.hex')

# 3. 트랜잭션 브로드캐스팅
docker-compose exec bitcoind bitcoin-cli sendrawtransaction "$SIGNED_TX"
```

#### 브로드캐스팅 결과 확인

```bash
# 브로드캐스팅 성공 시 트랜잭션 ID 반환
TXID=$(docker-compose exec -T bitcoind bitcoin-cli sendrawtransaction "서명된트랜잭션HEX")

# 트랜잭션 ID 확인
echo "트랜잭션 ID: $TXID"

# 트랜잭션 상태 확인
docker-compose exec bitcoind bitcoin-cli getrawtransaction "$TXID" true

# 메모리 풀에 있는지 확인
docker-compose exec bitcoind bitcoin-cli getmempoolentry "$TXID"
```

### 3. 트랜잭션 브로드캐스팅 예제

#### 완전한 예제 스크립트

```bash
#!/bin/bash

# 설정
RPC_USER="bitcoin"
RPC_PASSWORD="your_password"
RPC_PORT="8332"
CONTAINER_NAME="bitcoin-node"

# 함수: bitcoin-cli 실행
bitcoin_cli() {
    docker exec $CONTAINER_NAME bitcoin-cli -rpcuser=$RPC_USER -rpcpassword=$RPC_PASSWORD "$@"
}

# 1. 지갑 잔액 확인
echo "=== 잔액 확인 ==="
BALANCE=$(bitcoin_cli getbalance)
echo "현재 잔액: $BALANCE BTC"
echo ""

# 2. 새 주소 생성 (받는 주소)
echo "=== 받는 주소 생성 ==="
RECEIVE_ADDRESS=$(bitcoin_cli getnewaddress)
echo "받는 주소: $RECEIVE_ADDRESS"
echo ""

# 3. 트랜잭션 생성 및 전송
echo "=== 트랜잭션 전송 ==="
AMOUNT=0.001
TXID=$(bitcoin_cli sendtoaddress "$RECEIVE_ADDRESS" "$AMOUNT")
echo "트랜잭션 ID: $TXID"
echo ""

# 4. 트랜잭션 확인
echo "=== 트랜잭션 확인 ==="
bitcoin_cli getrawtransaction "$TXID" true | jq '.'
echo ""

# 5. 메모리 풀 확인
echo "=== 메모리 풀 확인 ==="
bitcoin_cli getmempoolentry "$TXID" | jq '.'
```

### 4. 수동 트랜잭션 생성 및 브로드캐스팅

지갑 없이 수동으로 트랜잭션을 생성하는 경우:

```bash
# 1. UTXO 확인 (필요한 경우)
docker-compose exec bitcoind bitcoin-cli listunspent

# 2. 원시 트랜잭션 생성
# 형식: createrawtransaction '[{"txid":"이전TXID","vout":인덱스}]' '{"받는주소":금액}'
RAW_TX=$(docker-compose exec -T bitcoind bitcoin-cli createrawtransaction \
  '[{"txid":"이전트랜잭션ID","vout":0}]' \
  '{"bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh":0.001}')

echo "원시 트랜잭션: $RAW_TX"

# 3. 트랜잭션 디코딩 (확인용)
docker-compose exec bitcoind bitcoin-cli decoderawtransaction "$RAW_TX"

# 4. 트랜잭션 서명
SIGNED_TX_JSON=$(docker-compose exec -T bitcoind bitcoin-cli signrawtransactionwithwallet "$RAW_TX")
SIGNED_TX=$(echo "$SIGNED_TX_JSON" | jq -r '.hex')
COMPLETE=$(echo "$SIGNED_TX_JSON" | jq -r '.complete')

if [ "$COMPLETE" = "true" ]; then
    echo "트랜잭션 서명 완료"
    
    # 5. 트랜잭션 브로드캐스팅
    TXID=$(docker-compose exec -T bitcoind bitcoin-cli sendrawtransaction "$SIGNED_TX")
    echo "브로드캐스팅 성공! 트랜잭션 ID: $TXID"
    
    # 6. 트랜잭션 확인
    docker-compose exec bitcoind bitcoin-cli getrawtransaction "$TXID" true
else
    echo "트랜잭션 서명 실패"
    echo "$SIGNED_TX_JSON"
fi
```

### 5. 트랜잭션 브로드캐스팅 주의사항

1. **수수료 확인**: 트랜잭션에 적절한 수수료가 포함되어 있는지 확인
   ```bash
   # 추정 수수료 확인
   docker-compose exec bitcoind bitcoin-cli estimatesmartfee 6
   ```

2. **트랜잭션 검증**: 브로드캐스팅 전에 트랜잭션을 검증
   ```bash
   # 트랜잭션 테스트 (실제 브로드캐스팅하지 않음)
   docker-compose exec bitcoind bitcoin-cli testmempoolaccept '["서명된트랜잭션HEX"]'
   ```

3. **이중 지출 방지**: 같은 UTXO를 두 번 사용하지 않도록 주의

4. **네트워크 확인**: 메인넷에서 테스트할 때는 소량으로 먼저 테스트

### 6. 트랜잭션 상태 모니터링

```bash
# 트랜잭션 ID로 상태 확인
TXID="트랜잭션ID"

# 트랜잭션 정보 조회
docker-compose exec bitcoind bitcoin-cli getrawtransaction "$TXID" true

# 메모리 풀에 있는지 확인
docker-compose exec bitcoind bitcoin-cli getmempoolentry "$TXID" 2>/dev/null && \
  echo "트랜잭션이 메모리 풀에 있습니다" || \
  echo "트랜잭션이 메모리 풀에 없습니다 (확인되었거나 거부됨)"

# 트랜잭션이 포함된 블록 확인
TX_INFO=$(docker-compose exec -T bitcoind bitcoin-cli getrawtransaction "$TXID" true)
BLOCK_HASH=$(echo "$TX_INFO" | jq -r '.blockhash')
if [ "$BLOCK_HASH" != "null" ]; then
    echo "트랜잭션이 블록에 포함됨: $BLOCK_HASH"
    docker-compose exec bitcoind bitcoin-cli getblock "$BLOCK_HASH" | jq '.height'
else
    echo "트랜잭션이 아직 블록에 포함되지 않음"
fi
```

---

## 문제 해결

### 1. 컨테이너가 시작되지 않음

```bash
# 로그 확인
docker-compose logs bitcoind

# 컨테이너 상태 확인
docker-compose ps -a

# 컨테이너 재시작
docker-compose restart bitcoind

# 컨테이너 재생성
docker-compose up -d --force-recreate bitcoind
```

### 2. RPC 연결 실패

```bash
# RPC 설정 확인
docker-compose exec bitcoind cat /home/bitcoin/.bitcoin/bitcoin.conf | grep rpc

# RPC 테스트
docker-compose exec bitcoind bitcoin-cli getnetworkinfo

# RPC 포트 확인
docker-compose exec bitcoind netstat -tlnp | grep 8332
```

### 3. 동기화가 느림

```bash
# 연결된 피어 수 확인
docker-compose exec bitcoind bitcoin-cli getconnectioncount

# 피어 정보 확인
docker-compose exec bitcoind bitcoin-cli getpeerinfo

# dbcache 증가 (bitcoin.conf 수정 후 재시작)
# dbcache=8000
```

### 4. 디스크 공간 부족

```bash
# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/bitcoin

# 디렉토리별 크기 확인
du -h --max-depth=1 /mnt/cryptocur-data/bitcoin | sort -hr

# 불필요한 로그 파일 삭제
docker-compose exec bitcoind find /home/bitcoin/.bitcoin -name "*.log" -delete

# 또는 호스트에서 직접 삭제
find /mnt/cryptocur-data/bitcoin -name "*.log" -delete
```

### 5. 트랜잭션 브로드캐스팅 실패

```bash
# 트랜잭션 검증
docker-compose exec bitcoind bitcoin-cli testmempoolaccept '["트랜잭션HEX"]'

# 에러 메시지 확인
docker-compose logs bitcoind | grep -i error

# 메모리 풀 정보 확인
docker-compose exec bitcoind bitcoin-cli getmempoolinfo
```

---

## 추가 리소스

- [Bitcoin Core 공식 문서](https://bitcoin.org/en/developer-documentation)
- [Bitcoin Core RPC API 문서](https://developer.bitcoin.org/reference/rpc/)
- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Compose 문서](https://docs.docker.com/compose/)

---

## 요약

이 가이드는 다음을 다룹니다:

1. ✅ **설치 전 시스템 확인**: 하드웨어, 네트워크, 포트, Docker 확인
2. ✅ **Docker 설치 및 설정**: Docker 및 Docker Compose 설치
3. ✅ **Bitcoin 노드 설치**: Docker Compose를 사용한 노드 설치
4. ✅ **노드 상태 확인**: 동기화 상태, 네트워크 연결, 컨테이너 상태 확인
5. ✅ **정보 조회**: 블록체인, 트랜잭션, 네트워크 정보 조회
6. ✅ **트랜잭션 브로드캐스팅**: 트랜잭션 생성, 서명, 브로드캐스팅 방법

이 가이드를 따라하면 Linux 서버에서 Bitcoin 노드를 성공적으로 설치하고 운영할 수 있습니다.
