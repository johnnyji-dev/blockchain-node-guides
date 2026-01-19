# LevelDB Lock 파일 오류 해결 가이드

## 🔍 에러 원인 분석

### 주요 에러 메시지

```
Fatal LevelDB error: IO error: lock /home/bitcoin/.bitcoin/blocks/index/LOCK: 
Resource temporarily unavailable

Error opening block database.
Please restart with -reindex or -reindex-chainstate to recover.
```

### 원인

1. **LevelDB Lock 파일 충돌**
   - 이전 bitcoind 프로세스가 비정상 종료되어 LevelDB lock 파일이 남음
   - 경로: `/mnt/cryptocur-data/bitcoin/blocks/index/LOCK`
   - 새로운 프로세스가 데이터베이스에 접근할 수 없음

2. **컨테이너 재시작 루프**
   - `restart: unless-stopped` 정책으로 인해 실패 → 재시작 → 실패 반복
   - 이전 프로세스가 완전히 종료되기 전에 새로운 프로세스가 시작됨

3. **RPC 바인딩 실패** (부차적 문제)
   - `Binding RPC on address 0.0.0.0 port 8332 failed.`
   - 이전 프로세스가 포트를 점유하고 있을 수 있음

## 🔧 해결 방법

### 방법 1: LevelDB Lock 파일 제거 (권장)

#### 1단계: 컨테이너 완전 중지

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker

# 컨테이너 중지 및 제거
docker-compose down

# 또는 강제 중지
docker stop bitcoin-node
docker rm bitcoin-node
```

#### 2단계: 모든 Lock 파일 제거

```bash
# LevelDB Lock 파일 제거
sudo rm -f /mnt/cryptocur-data/bitcoin/blocks/index/LOCK

# 다른 LevelDB Lock 파일들도 확인 및 제거
sudo find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f

# 모든 LOCK 파일 제거 (주의: 데이터 손상 위험)
sudo find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f -delete

# Bitcoin Core lock 파일도 제거
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock
sudo rm -f /mnt/cryptocur-data/bitcoin/bitcoind.pid
```

#### 3단계: 컨테이너 재시작

```bash
docker-compose up -d
```

### 방법 2: 재인덱싱으로 복구

LevelDB lock 파일을 제거해도 문제가 지속되면 재인덱싱이 필요할 수 있습니다.

#### 1단계: 컨테이너 중지 및 Lock 파일 제거

```bash
docker-compose down
sudo rm -f /mnt/cryptocur-data/bitcoin/blocks/index/LOCK
sudo find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f -delete
```

#### 2단계: 재인덱싱 옵션 추가

`docker-compose.yml`의 command 섹션에 `-reindex-chainstate` 옵션 추가:

```yaml
command:
  - bitcoind
  - -printtoconsole
  - -txindex=1
  - -dbcache=4500
  - -server=1
  - -reindex-chainstate  # 추가
  - -rpcuser=${BITCOIN_RPC_USER:-bitcoin}
  - -rpcpassword=${BITCOIN_RPC_PASSWORD:-changeme}
  - -rpcbind=0.0.0.0
  - -rpcallowip=127.0.0.1
```

#### 3단계: 컨테이너 시작

```bash
docker-compose up -d
```

**주의**: 재인덱싱은 시간이 오래 걸릴 수 있습니다.

### 방법 3: 완전 재인덱싱 (최후의 수단)

모든 인덱스를 다시 구축해야 하는 경우:

```yaml
command:
  - bitcoind
  - -printtoconsole
  - -txindex=1
  - -dbcache=4500
  - -server=1
  - -reindex  # 완전 재인덱싱 (시간이 매우 오래 걸림)
  - -rpcuser=${BITCOIN_RPC_USER:-bitcoin}
  - -rpcpassword=${BITCOIN_RPC_PASSWORD:-changeme}
  - -rpcbind=0.0.0.0
  - -rpcallowip=127.0.0.1
```

### 방법 4: 재시작 정책 일시 변경

재시작 루프를 방지하기 위해 재시작 정책을 일시적으로 변경:

```bash
# 재시작 정책 변경
docker update --restart=no bitcoin-node

# 컨테이너 중지
docker stop bitcoin-node

# Lock 파일 제거
sudo rm -f /mnt/cryptocur-data/bitcoin/blocks/index/LOCK
sudo find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f -delete

# 컨테이너 시작
docker start bitcoin-node

# 재시작 정책 복원
docker update --restart=unless-stopped bitcoin-node
```

## 🎯 빠른 해결 명령어 (한 번에 실행)

```bash
# 1. 컨테이너 중지 및 제거
cd ~/blockchain-node-guides/chains/bitcoin/docker
docker-compose down

# 2. 모든 Lock 파일 제거
sudo rm -f /mnt/cryptocur-data/bitcoin/blocks/index/LOCK
sudo find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f -delete
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock
sudo rm -f /mnt/cryptocur-data/bitcoin/bitcoind.pid

# 3. 잠시 대기 (프로세스 완전 종료 대기)
sleep 5

# 4. 컨테이너 재시작
docker-compose up -d

# 5. 로그 확인
docker-compose logs -f
```

## 🔍 문제 진단 단계

### 1단계: Lock 파일 확인

```bash
# LevelDB Lock 파일 확인
ls -la /mnt/cryptocur-data/bitcoin/blocks/index/LOCK

# 모든 LOCK 파일 찾기
find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f

# Lock 파일의 소유자 및 권한 확인
sudo ls -la /mnt/cryptocur-data/bitcoin/blocks/index/
```

### 2단계: 실행 중인 프로세스 확인

```bash
# 컨테이너 내부 프로세스 확인
docker exec bitcoin-node ps aux | grep bitcoind

# 호스트에서 bitcoind 프로세스 확인
ps aux | grep bitcoind

# 포트 사용 확인
sudo netstat -tlnp | grep 8332
sudo netstat -tlnp | grep 8333
```

### 3단계: 컨테이너 상태 확인

```bash
# 컨테이너 상태
docker ps -a | grep bitcoin

# 컨테이너 로그
docker logs --tail=100 bitcoin-node

# 실시간 로그
docker logs -f bitcoin-node
```

## 📋 단계별 해결 체크리스트

1. ✅ **컨테이너 완전 중지**
   ```bash
   docker-compose down
   ```

2. ✅ **Lock 파일 제거**
   ```bash
   sudo rm -f /mnt/cryptocur-data/bitcoin/blocks/index/LOCK
   sudo find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f -delete
   ```

3. ✅ **대기 시간 확보**
   ```bash
   sleep 5
   ```

4. ✅ **컨테이너 재시작**
   ```bash
   docker-compose up -d
   ```

5. ✅ **로그 확인**
   ```bash
   docker-compose logs -f
   ```

## 🛡️ 예방 방법

### 1. 정상 종료 사용

```bash
# 정상 종료 (권장)
docker-compose stop

# 또는 bitcoind 정상 종료
docker-compose exec bitcoind bitcoin-cli stop

# 강제 종료는 피하기
# docker kill bitcoin-node  # 비권장
```

### 2. 시작 전 Lock 파일 자동 제거 스크립트

`docker-compose.yml`의 command를 수정하여 시작 전에 lock 파일을 제거:

```yaml
command:
  - /bin/bash
  - -c
  - |
    # Lock 파일 제거
    rm -f /home/bitcoin/.bitcoin/.lock
    rm -f /home/bitcoin/.bitcoin/bitcoind.pid
    find /home/bitcoin/.bitcoin -name "LOCK" -type f -delete
    # bitcoind 실행
    exec bitcoind -printtoconsole -txindex=1 -dbcache=4500 -server=1 -rpcuser=${BITCOIN_RPC_USER:-bitcoin} -rpcpassword=${BITCOIN_RPC_PASSWORD:-changeme} -rpcbind=0.0.0.0 -rpcallowip=127.0.0.1
```

### 3. 재시작 지연 시간 추가

`docker-compose.yml`에 재시작 지연 시간 추가:

```yaml
restart: unless-stopped
# 또는
restart: "on-failure:5"  # 5번 실패 후 재시작 중지
```

## 📝 추가 정보

### LevelDB Lock 파일이란?

- **위치**: `/home/bitcoin/.bitcoin/blocks/index/LOCK`
- **목적**: LevelDB 데이터베이스에 동시 접근을 방지
- **문제**: 비정상 종료 시 lock 파일이 남아있어 새로운 프로세스가 데이터베이스에 접근 불가

### Lock 파일 위치

- **LevelDB Block Index**: `/mnt/cryptocur-data/bitcoin/blocks/index/LOCK`
- **LevelDB Chain State**: `/mnt/cryptocur-data/bitcoin/chainstate/LOCK` (있는 경우)
- **LevelDB Transaction Index**: `/mnt/cryptocur-data/bitcoin/indexes/txindex/LOCK` (txindex 사용 시)
- **LevelDB Block Filter Index**: `/mnt/cryptocur-data/bitcoin/indexes/blockfilter/basic/LOCK` (blockfilterindex 사용 시)

### 안전하게 Lock 파일 제거하는 시점

1. ✅ **컨테이너가 완전히 중지된 후**
2. ✅ **bitcoind 프로세스가 실행 중이 아닐 때**
3. ✅ **데이터베이스 작업이 진행 중이 아닐 때**
4. ✅ **충분한 대기 시간 후** (최소 5초)

### 주의사항

⚠️ **Lock 파일을 제거할 때 주의사항**:
- bitcoind가 실행 중일 때 제거하면 데이터 손상 위험
- 항상 컨테이너를 먼저 중지한 후 제거
- 여러 컨테이너가 같은 데이터를 사용하는 경우 동시 실행 방지
- 재인덱싱은 시간이 오래 걸릴 수 있음 (블록체인 크기에 따라)

## 🔄 재인덱싱 옵션 비교

| 옵션 | 설명 | 시간 | 데이터 영향 |
|------|------|------|------------|
| `-reindex` | 모든 인덱스 재구축 | 매우 오래 걸림 | 블록 파일은 유지 |
| `-reindex-chainstate` | 체인 상태만 재구축 | 상대적으로 빠름 | 블록 파일은 유지 |
| Lock 파일 제거만 | 인덱스 유지 | 즉시 | 없음 (권장) |

## 결론

**가장 빠른 해결 방법**:

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker
docker-compose down
sudo rm -f /mnt/cryptocur-data/bitcoin/blocks/index/LOCK
sudo find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f -delete
sleep 5
docker-compose up -d
```

이 방법으로 대부분의 LevelDB lock 파일 문제를 해결할 수 있습니다.

문제가 지속되면 재인덱싱 옵션을 사용하거나, 더 자세한 진단을 위해 `-debug=leveldb` 옵션을 추가하세요.
