# LevelDB Chainstate 손상 오류 해결 가이드

## 🔍 에러 원인 분석

### 주요 에러 메시지

```
Fatal LevelDB error: Corruption: 5409 missing files; e.g.: /home/bitcoin/.bitcoin/chainstate/337641.ldb

Error opening block database.
Please restart with -reindex or -reindex-chainstate to recover.
```

### 원인

1. **LevelDB Chainstate 손상**
   - `chainstate` 디렉토리의 LevelDB 파일들이 손상되었거나 누락됨
   - 5,409개의 파일이 누락됨
   - 예시: `/home/bitcoin/.bitcoin/chainstate/337641.ldb`

2. **가능한 원인**
   - 이전 lock 파일 제거 과정에서 데이터 손상
   - 디스크 공간 부족으로 인한 파일 삭제
   - 비정상 종료로 인한 데이터베이스 손상
   - 디스크 I/O 오류

3. **컨테이너 재시작 루프**
   - `restart: unless-stopped` 정책으로 인해 실패 → 재시작 → 실패 반복
   - bitcoind가 시작 실패 → 종료 → 재시작 → 실패 반복

## 🔧 해결 방법

### 방법 1: 재인덱싱으로 복구 (권장)

#### 1단계: 컨테이너 중지

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker

# 컨테이너 중지
sudo docker-compose stop

# 또는 강제 중지
sudo docker stop bitcoin-node
```

#### 2단계: docker-compose.yml에 재인덱싱 옵션 추가

`docker-compose.yml`의 command 섹션에 `-reindex-chainstate` 옵션 추가:

```yaml
command:
  - bitcoind
  - -printtoconsole
  - -txindex=1
  - -dbcache=4500
  - -server=1
  - -reindex-chainstate  # 추가: 체인 상태 재인덱싱
  - -rpcuser=${BITCOIN_RPC_USER:-bitcoin}
  - -rpcpassword=${BITCOIN_RPC_PASSWORD:-changeme}
  - -rpcbind=0.0.0.0
  - -rpcallowip=127.0.0.1
  - -rpcallowip=172.21.0.0/16
```

#### 3단계: 컨테이너 시작

```bash
docker-compose up -d
```

**주의**: 재인덱싱은 시간이 오래 걸릴 수 있습니다 (수 시간 ~ 수십 시간).

#### 4단계: 재인덱싱 완료 후 옵션 제거

재인덱싱이 완료되면 `-reindex-chainstate` 옵션을 제거하고 컨테이너를 재시작:

```bash
# docker-compose.yml에서 -reindex-chainstate 제거
# 컨테이너 재시작
docker-compose down
docker-compose up -d
```

### 방법 2: 일회성 재인덱싱 실행

임시로 재인덱싱만 실행하고 설정 파일은 변경하지 않음:

```bash
# 1. 컨테이너 중지
sudo docker-compose stop

# 2. 일회성 재인덱싱 실행
sudo docker-compose run --rm bitcoind bitcoind \
  -reindex-chainstate \
  -printtoconsole \
  -txindex=1 \
  -dbcache=4500 \
  -server=1 \
  -rpcuser=bitcoin \
  -rpcpassword=firpeng \
  -rpcbind=0.0.0.0 \
  -rpcallowip=127.0.0.1 \
  -rpcallowip=172.21.0.0/16

# 3. 재인덱싱 완료 후 정상 시작
docker-compose up -d
```

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
  - -rpcallowip=172.21.0.0/16
```

**주의**: `-reindex`는 `-reindex-chainstate`보다 훨씬 오래 걸립니다.

### 방법 4: 재시작 정책 일시 변경

재시작 루프를 방지하기 위해 재시작 정책을 일시적으로 변경:

```bash
# 재시작 정책 변경
sudo docker update --restart=no bitcoin-node

# 컨테이너 중지
sudo docker stop bitcoin-node

# 재인덱싱 옵션으로 시작
# (docker-compose.yml 수정 후)
docker-compose up -d

# 재인덱싱 완료 후 재시작 정책 복원
sudo docker update --restart=unless-stopped bitcoin-node
```

## 🎯 빠른 해결 명령어 (한 번에 실행)

### 옵션 1: 재인덱싱으로 복구 (권장)

```bash
# 1. 컨테이너 중지
cd ~/blockchain-node-guides/chains/bitcoin/docker
sudo docker-compose stop

# 2. docker-compose.yml에 -reindex-chainstate 추가
# (파일 편집 필요)

# 3. 컨테이너 시작
docker-compose up -d

# 4. 로그 확인 (재인덱싱 진행 상황 확인)
docker-compose logs -f
```

### 옵션 2: 일회성 재인덱싱

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker
sudo docker-compose stop
sudo docker-compose run --rm bitcoind bitcoind -reindex-chainstate -printtoconsole -txindex=1 -dbcache=4500 -server=1 -rpcuser=bitcoin -rpcpassword=firpeng -rpcbind=0.0.0.0 -rpcallowip=127.0.0.1 -rpcallowip=172.21.0.0/16
```

## 🔍 문제 진단 단계

### 1단계: 손상된 파일 확인

```bash
# chainstate 디렉토리 확인
ls -la /mnt/cryptocur-data/bitcoin/chainstate/ | head -20

# 손상된 파일 확인
find /mnt/cryptocur-data/bitcoin/chainstate -name "*.ldb" | wc -l

# 디스크 공간 확인
df -h /mnt/cryptocur-data/bitcoin
```

### 2단계: 로그 확인

```bash
# 컨테이너 로그 확인
docker logs bitcoin-node | grep -i "corruption\|missing files"

# 최근 에러 확인
docker logs --tail=100 bitcoin-node | grep -i error
```

### 3단계: 데이터 디렉토리 상태 확인

```bash
# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/bitcoin

# chainstate 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/bitcoin/chainstate

# 블록 파일 확인
ls -lh /mnt/cryptocur-data/bitcoin/blocks/ | tail -10
```

## 📋 단계별 해결 체크리스트

1. ✅ **컨테이너 중지**
   ```bash
   sudo docker-compose stop
   ```

2. ✅ **재인덱싱 옵션 추가**
   ```yaml
   - -reindex-chainstate
   ```

3. ✅ **컨테이너 시작**
   ```bash
   docker-compose up -d
   ```

4. ✅ **로그 모니터링**
   ```bash
   docker-compose logs -f
   ```

5. ✅ **재인덱싱 완료 확인**
   - 로그에서 "Done loading" 메시지 확인
   - 블록체인 동기화 완료 확인

6. ✅ **재인덱싱 옵션 제거**
   - `-reindex-chainstate` 제거
   - 컨테이너 재시작

## ⏱️ 재인덱싱 시간 예상

### -reindex-chainstate (체인 상태만)
- **예상 시간**: 1-6시간 (블록체인 크기에 따라)
- **디스크 I/O**: 중간
- **CPU 사용량**: 중간

### -reindex (완전 재인덱싱)
- **예상 시간**: 12-48시간 이상
- **디스크 I/O**: 매우 높음
- **CPU 사용량**: 높음

## 🛡️ 예방 방법

### 1. 정상 종료 사용

```bash
# 정상 종료 (권장)
docker-compose exec bitcoind bitcoin-cli stop
docker-compose stop

# 강제 종료는 피하기
# docker kill bitcoin-node  # 비권장
```

### 2. 디스크 공간 모니터링

```bash
# 디스크 공간 확인
df -h /mnt/cryptocur-data

# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/bitcoin
```

### 3. 정기 백업

```bash
# 데이터 백업
tar -czf bitcoin-backup-$(date +%Y%m%d).tar.gz /mnt/cryptocur-data/bitcoin
```

### 4. 디스크 I/O 모니터링

```bash
# 디스크 I/O 확인
iostat -x 1

# 디스크 오류 확인
dmesg | grep -i error
```

## 📝 추가 정보

### LevelDB Chainstate란?

- **위치**: `/home/bitcoin/.bitcoin/chainstate`
- **목적**: UTXO (Unspent Transaction Output) 세트 저장
- **크기**: 약 8-10GB (메인넷)
- **중요성**: 매우 중요 (손상 시 재인덱싱 필요)

### 재인덱싱 옵션 비교

| 옵션 | 설명 | 시간 | 데이터 영향 |
|------|------|------|------------|
| `-reindex` | 모든 인덱스 재구축 | 매우 오래 걸림 | 블록 파일은 유지 |
| `-reindex-chainstate` | 체인 상태만 재구축 | 상대적으로 빠름 | 블록 파일은 유지 |

### 재인덱싱 진행 상황 확인

```bash
# 로그에서 진행 상황 확인
docker logs -f bitcoin-node | grep -i "progress\|verification\|reindex"

# 블록체인 정보 확인 (재인덱싱 중에도 가능)
docker exec bitcoin-node bitcoin-cli getblockchaininfo | grep verificationprogress
```

## 🔄 재인덱싱 중 주의사항

### 1. 컨테이너 중지 금지
- 재인덱싱 중 컨테이너를 중지하면 처음부터 다시 시작해야 함
- 가능하면 재인덱싱이 완료될 때까지 기다리기

### 2. 리소스 모니터링
- 재인덱싱은 CPU와 디스크 I/O를 많이 사용
- 다른 작업에 영향을 줄 수 있음

### 3. 로그 모니터링
- 재인덱싱 진행 상황을 로그로 확인
- 에러 발생 시 즉시 대응

## 결론

**문제 원인**: LevelDB chainstate 데이터베이스 파일 손상 (5,409개 파일 누락)

**해결 방법**: `-reindex-chainstate` 옵션으로 재인덱싱

**빠른 해결**:
```bash
# 1. 컨테이너 중지
sudo docker-compose stop

# 2. docker-compose.yml에 -reindex-chainstate 추가

# 3. 컨테이너 시작
docker-compose up -d

# 4. 로그 모니터링
docker-compose logs -f
```

재인덱싱은 시간이 오래 걸릴 수 있지만, 블록 파일은 유지되므로 전체 블록체인을 다시 다운로드할 필요는 없습니다.
