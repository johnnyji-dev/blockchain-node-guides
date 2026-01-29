# Stellar 노드 Docker 가이드

Stellar 공식 Quickstart 이미지를 사용하여 Stellar 노드를 실행하는 방법입니다.

## 빠른 시작

### 1. 환경 변수 설정 (선택사항)

```bash
# .env 파일 복사
cp .env.example .env

# PostgreSQL 비밀번호 변경 (필수!)
nano .env
# POSTGRES_PASSWORD를 안전한 비밀번호로 변경
```

### 2. 데이터 디렉토리 준비

```bash
# 데이터 디렉토리 생성
sudo mkdir -p /mnt/cryptocur-data/stellar

# 권한 설정 (Quickstart는 UID 10011001 사용)
sudo chown -R 10011001:10011001 /mnt/cryptocur-data/stellar
sudo chmod -R 755 /mnt/cryptocur-data/stellar
```

### 3. Docker Compose로 실행

```bash
# 테스트넷 노드 시작 (기본값)
docker-compose up -d

# 또는 특정 네트워크 지정
NETWORK=pubnet docker-compose up -d

# 로그 확인
docker-compose logs -f
```

## 네트워크 선택

### Testnet (기본값, 권장)
```bash
NETWORK=testnet docker-compose up -d
```
- 개발 및 테스트용 네트워크
- 동기화 시간: 수 시간
- 디스크 요구사항: ~50GB

### Pubnet (메인넷)
```bash
NETWORK=pubnet docker-compose up -d
```
- 실제 거래가 이루어지는 네트워크
- 동기화 시간: 2-7일
- 디스크 요구사항: ~1TB
- ⚠️ 많은 리소스 필요

### Local (로컬 개발)
```bash
NETWORK=local docker-compose up -d
```
- 로컬 개발/테스트 네트워크
- 원장 생성: 1초마다
- 빠른 테스트에 적합

### Futurenet
```bash
NETWORK=futurenet docker-compose up -d
```
- 미래 프로토콜 변경 테스트 네트워크

## 서비스 구성

Quickstart 이미지는 다음 서비스를 포함합니다:

- **stellar-core**: 블록체인 코어 노드
- **stellar-horizon**: REST API 서버
- **stellar-rpc**: RPC 서버 (Soroban 스마트 컨트랙트용)
- **friendbot**: 테스트넷 계정 생성용 Faucet
- **lab**: Stellar Lab 웹 UI
- **galexie**: 원장 메타 익스포터 (local 네트워크만)

### 서비스 활성화/비활성화

`.env` 파일에서 `ENABLE` 변수로 제어:

```bash
# 모든 주요 서비스 (기본값)
ENABLE=core,horizon,rpc

# RPC만
ENABLE=rpc

# Core와 Horizon만
ENABLE=core,horizon

# Lab 포함
ENABLE=core,horizon,rpc,lab
```

## 포트

| 포트 | 서비스 | 설명 |
|------|--------|------|
| 8100 | Horizon, RPC, Lab, Friendbot | 메인 HTTP 포트 (외부 노출 가능, Solana와 충돌 방지) |
| 11625 | stellar-core | P2P 네트워크 포트 |
| 11626 | stellar-core | HTTP 관리 포트 (신뢰 네트워크만) |
| 5433 | PostgreSQL | 데이터베이스 포트 (로컬호스트만, Ethereum과 충돌 방지) |
| 6060 | Horizon | 관리 포트 (선택사항) |
| 6061 | RPC | 관리 포트 (선택사항) |

**참고**: 
- 호스트 포트 8100은 컨테이너 내부 포트 8000에 매핑됩니다
- Solana(8000-8025)와 Ethereum PostgreSQL(5432)과의 충돌을 방지하기 위해 변경되었습니다

## 노드 상태 확인

### 컨테이너 상태

```bash
# 컨테이너 상태 확인
docker ps | grep stellar

# 컨테이너 로그 확인
docker-compose logs -f

# 특정 서비스 로그만
docker-compose logs -f stellar | grep horizon
```

### Horizon API

```bash
# 최신 원장 조회
curl http://localhost:8100/ledgers?limit=1&order=desc

# 계정 정보 조회
curl http://localhost:8100/accounts/GACCOUNT...

# 트랜잭션 조회
curl http://localhost:8100/transactions?limit=10

# Horizon 상태
curl http://localhost:8100/
```

### stellar-core HTTP API

```bash
# 노드 정보
curl http://localhost:11626/info

# 피어 정보
curl http://localhost:11626/peers

# 메트릭
curl http://localhost:11626/metrics
```

### RPC API

```bash
# Health check
curl -X POST http://localhost:8100/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'

# 최신 원장
curl -X POST http://localhost:8100/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getLatestLedger"}'
```

## Stellar Lab

웹 UI는 다음 주소에서 접근 가능합니다:

```
http://localhost:8100/lab
```

Lab에서 다음을 수행할 수 있습니다:
- 계정 생성 및 관리
- 트랜잭션 생성 및 서명
- Horizon API 테스트
- RPC API 테스트
- Friendbot으로 계정 자금 조달

## Friendbot (테스트넷/퓨처넷)

테스트넷에서 새 계정을 생성하려면:

```bash
curl "http://localhost:8100/friendbot?addr=GACCOUNT..."
```

## 데이터 관리

### Persistent Mode

볼륨 마운트(`/mnt/cryptocur-data/stellar:/opt/stellar`)를 사용하면:
- 모든 데이터가 호스트에 저장됨
- 컨테이너 재시작 후에도 데이터 유지
- 설정 파일 수정 가능

### Ephemeral Mode

볼륨을 마운트하지 않으면:
- 컨테이너 종료 시 모든 데이터 삭제
- 개발/테스트에 적합

## 문제 해결

### 컨테이너가 시작되지 않음

```bash
# 로그 확인
docker-compose logs stellar

# 컨테이너 재시작
docker-compose restart stellar
```

### 디스크 공간 부족

```bash
# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/stellar

# 디렉토리별 크기 확인
du -h --max-depth=1 /mnt/cryptocur-data/stellar | sort -hr
```

### PostgreSQL 연결 오류

```bash
# PostgreSQL 상태 확인
docker-compose exec stellar psql -U stellar -d horizon -c "SELECT 1"

# 비밀번호 확인
# .env 파일의 POSTGRES_PASSWORD 확인
```

### 동기화 문제

```bash
# Core 상태 확인
curl http://localhost:11626/info | jq '.info.state'

# Horizon 동기화 상태
curl http://localhost:8100/ | jq '.core_latest_ledger, .history_latest_ledger'
```

## 응답 속도 / 성능

**포트 번호(8100 등)는 응답 속도와 무관합니다.** 느릴 때 확인할 것:

### 1. 동기화 상태
동기화 중이면 Horizon/RPC 응답이 느리거나 불안정할 수 있습니다.

```bash
# 동기화 완료 여부 확인
curl -s http://localhost:8100/ | jq '.core_latest_ledger == .history_latest_ledger'
# true면 동기화 완료
```

### 2. 컨테이너 설정 (이미 반영)
- **shm_size: 512mb** – PostgreSQL·Horizon용 공유 메모리 확대 (기본 64MB → 512MB). 적용 후 재시작:
  ```bash
  docker-compose down && docker-compose up -d
  ```

### 3. 호스트 리소스 확인 명령어

응답 속도 개선을 위해 아래 순서로 확인하세요.

#### 메모리 (RAM)

```bash
# 전체 메모리 및 사용량
free -h

# 상세: 사용 가능 메모리(available)가 2GB 미만이면 부족
free -h && echo "---" && cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable"
```

- **권장**: Stellar만 돌릴 때 최소 8GB, pubnet 16GB+
- **available** 이 계속 적으면 스왑/디스크 I/O 증가로 느려짐

#### CPU

```bash
# CPU 코어 수
nproc

# 실시간 부하 (1/5/15분 평균, 1.0 = 1코어 100%)
uptime

# 프로세스별 CPU 사용률 (q 종료)
top -b -n 1 | head -20
# 또는
htop
```

- **권장**: 최소 4코어, pubnet 8코어+
- `load average` 가 코어 수보다 크게 유지되면 CPU 병목

#### 디스크 용량 및 사용량

```bash
# Stellar 데이터 경로 용량
df -h /mnt/cryptocur-data/stellar

# 전체 디스크
df -h

# Stellar 데이터 디렉터리 크기
du -sh /mnt/cryptocur-data/stellar
du -h --max-depth=1 /mnt/cryptocur-data/stellar 2>/dev/null | sort -hr | head -10
```

- **권장**: 여유 공간 20% 이상 (testnet ~50GB, pubnet ~1TB)
- **부족 시**: 동기화 실패·재시도·느린 DB 쓰기로 응답 지연

#### 디스크가 SSD인지 여부 (I/O 속도)

```bash
# 디스크 모델·타입 (SSD면 "SSD" 또는 "NVMe" 등으로 표기)
lsblk -d -o NAME,MODEL,SIZE,ROTA
# ROTA=0 → SSD, ROTA=1 → HDD

# Stellar 볼륨이 있는 디스크 확인
df /mnt/cryptocur-data/stellar | tail -1 | awk '{print $1}' | xargs lsblk -d -o NAME,MODEL,ROTA -n
```

- **ROTA 0**: SSD (빠름), **ROTA 1**: HDD (DB 부하 시 느림)

#### 디스크 I/O 부하

```bash
# I/O 대기·사용률 (설치 필요: sudo apt install iotop)
sudo iotop -b -n 3 -o

# 간단 확인: 디스크 쓰기 대기 시간
iostat -x 1 3 2>/dev/null || (echo "sysstat 필요: sudo apt install sysstat")
```

- **%util** 이 90% 근처로 오래 유지되면 디스크 병목

#### Docker 컨테이너 리소스 사용량

```bash
# Stellar 컨테이너 CPU/메모리 실시간
docker stats stellar-node --no-stream

# 모든 컨테이너
docker stats --no-stream
```

- Stellar가 메모리를 거의 다 쓰거나, 다른 컨테이너가 CPU/메모리를 많이 쓰면 Stellar 응답이 느려질 수 있음

#### 한 번에 점검하는 요약 스크립트

```bash
echo "=== 메모리 ===" && free -h
echo "" && echo "=== CPU 코어 / 부하 ===" && nproc && uptime
echo "" && echo "=== Stellar 디스크 ===" && df -h /mnt/cryptocur-data/stellar
echo "" && echo "=== 디스크 타입(ROTA 0=SSD) ===" && lsblk -d -o NAME,MODEL,SIZE,ROTA
echo "" && echo "=== Stellar 컨테이너 리소스 ===" && docker stats stellar-node --no-stream
echo "" && echo "=== 동기화 상태 ===" && curl -s http://localhost:8100/ | jq '{core: .core_latest_ledger, history: .history_latest_ledger, synced: (.core_latest_ledger == .history_latest_ledger)}'
```

#### 정리: 확인 포인트

| 확인 항목 | 명령어 | 권장/주의 |
|----------|--------|-----------|
| 메모리 여유 | `free -h` | available 2GB+ |
| CPU 부하 | `uptime` | load average < 코어 수 |
| 디스크 여유 | `df -h /mnt/cryptocur-data/stellar` | 여유 20%+ |
| SSD 여부 | `lsblk -d -o NAME,ROTA` | ROTA=0 (SSD) |
| 컨테이너 사용량 | `docker stats stellar-node --no-stream` | 메모리 여유 확인 |
| 동기화 완료 | `curl -s localhost:8100/ \| jq .core_latest_ledger,.history_latest_ledger` | 두 값 같으면 동기화 완료 |

### 4. 컨테이너 메모리 제한 완화 (선택)
호스트에 메모리 여유가 있으면 컨테이너에 더 할당:

```bash
# 실행 중인 컨테이너에 메모리 제한 설정 (예: 4GB)
docker update --memory 4g stellar-node
```

### 5. 다른 노드와 리소스 경쟁
Bitcoin, Ethereum, Solana 등이 같은 서버에서 돌면 CPU/메모리/디스크를 나눠 쓰므로, Stellar만 느리다면 다른 컨테이너 리소스를 줄이거나 Stellar 전용 메모리를 늘려보세요.

---

## 보안 권장사항

1. **PostgreSQL 비밀번호**: 강력한 비밀번호 사용
2. **포트 노출**: 
   - 8100 포트는 외부 노출 가능 (Horizon은 인터넷 접근 가능하도록 설계됨)
   - 11626 포트는 신뢰할 수 있는 네트워크에만 노출
   - 5433 포트는 로컬호스트만 노출 (현재 설정)
3. **방화벽**: 호스트 방화벽 설정
4. **정기 업데이트**: 최신 이미지 태그 사용

## 추가 리소스

- [Stellar Quickstart GitHub](https://github.com/stellar/quickstart)
- [Stellar 공식 문서](https://developers.stellar.org/)
- [Horizon API 문서](https://developers.stellar.org/api)
- [RPC API 문서](https://developers.stellar.org/docs/data/rpc)
- [Stellar Lab](https://lab.stellar.org)
