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
| 8000 | Horizon, RPC, Lab, Friendbot | 메인 HTTP 포트 (외부 노출 가능) |
| 11625 | stellar-core | P2P 네트워크 포트 |
| 11626 | stellar-core | HTTP 관리 포트 (신뢰 네트워크만) |
| 5432 | PostgreSQL | 데이터베이스 포트 (로컬호스트만) |
| 6060 | Horizon | 관리 포트 (선택사항) |
| 6061 | RPC | 관리 포트 (선택사항) |

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
curl http://localhost:8000/ledgers?limit=1&order=desc

# 계정 정보 조회
curl http://localhost:8000/accounts/GACCOUNT...

# 트랜잭션 조회
curl http://localhost:8000/transactions?limit=10

# Horizon 상태
curl http://localhost:8000/
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
curl -X POST http://localhost:8000/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'

# 최신 원장
curl -X POST http://localhost:8000/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getLatestLedger"}'
```

## Stellar Lab

웹 UI는 다음 주소에서 접근 가능합니다:

```
http://localhost:8000/lab
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
curl "http://localhost:8000/friendbot?addr=GACCOUNT..."
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
curl http://localhost:8000/ | jq '.core_latest_ledger, .history_latest_ledger'
```

## 보안 권장사항

1. **PostgreSQL 비밀번호**: 강력한 비밀번호 사용
2. **포트 노출**: 
   - 8000 포트는 외부 노출 가능 (Horizon은 인터넷 접근 가능하도록 설계됨)
   - 11626 포트는 신뢰할 수 있는 네트워크에만 노출
   - 5432 포트는 로컬호스트만 노출 (현재 설정)
3. **방화벽**: 호스트 방화벽 설정
4. **정기 업데이트**: 최신 이미지 태그 사용

## 추가 리소스

- [Stellar Quickstart GitHub](https://github.com/stellar/quickstart)
- [Stellar 공식 문서](https://developers.stellar.org/)
- [Horizon API 문서](https://developers.stellar.org/api)
- [RPC API 문서](https://developers.stellar.org/docs/data/rpc)
- [Stellar Lab](https://lab.stellar.org)
