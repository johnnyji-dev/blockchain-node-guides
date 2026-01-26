# Stellar 노드 Docker 가이드

Docker를 사용하여 stellar-core (Core Node)와 horizon (API Server)를 통합 실행하는 방법입니다.

## 빠른 시작

### 1. 데이터 디렉토리 준비

```bash
# 데이터 디렉토리 생성
sudo mkdir -p /mnt/cryptocur-data/stellar/{core,horizon,postgres}

# 권한 설정
sudo chown -R 1000:1000 /mnt/cryptocur-data/stellar
sudo chmod -R 755 /mnt/cryptocur-data/stellar
```

### 2. 환경 변수 설정 (선택사항)

```bash
# .env 파일 생성 (선택사항)
cat > .env << EOF
# 네트워크 모드: public (기본값), testnet
NETWORK=public

# PostgreSQL 설정
POSTGRES_USER=stellar
POSTGRES_PASSWORD=changeme_strong_password

# Horizon 설정
HORIZON_PORT=8000
INGEST=true
EOF
```

### 3. Docker Compose로 실행

```bash
# 이미지 빌드 및 컨테이너 시작 (최초 빌드는 30-60분 소요)
docker compose up -d

# 로그 확인
docker compose logs -f stellar

# 컨테이너 상태 확인
docker compose ps
```

### 4. 노드 상태 확인

```bash
# stellar-core 상태 확인
curl http://localhost:11626/info

# stellar-core 동기화 상태
docker compose exec stellar stellar-core --conf /opt/stellar/stellar-core.cfg http-command 'info'

# Horizon API 확인
curl http://localhost:8000/

# Horizon 동기화 상태
curl http://localhost:8000/ledgers?limit=1&order=desc
```

## 파일 구조

```
docker/
├── Dockerfile              # Docker 이미지 빌드 파일
├── docker-compose.yml      # Docker Compose 설정
├── launcher.sh             # stellar-core와 horizon 실행 스크립트
├── stellar-core.cfg        # stellar-core 설정 템플릿
├── docker-readme.md        # 상세 가이드
└── README.md               # 이 파일
```

## Stellar 노드 구성

이 Docker 설정은 **stellar-core (Core Node)**, **horizon (API Server)**, **PostgreSQL (Database)**를 모두 포함하는 통합 노드입니다.

### stellar-core
- **공식 릴리스**: [https://github.com/stellar/stellar-core/releases](https://github.com/stellar/stellar-core/releases)
- **버전**: v22.0.0
- **역할**: 블록체인 합의, P2P 네트워크, 트랜잭션 검증
- **포트**: 
  - 11625: P2P 네트워크
  - 11626: HTTP (관리용 API)

### horizon
- **공식 릴리스**: [https://github.com/stellar/go/releases](https://github.com/stellar/go/releases)
- **버전**: v2.32.0
- **역할**: REST API 서버, 데이터 조회
- **포트**:
  - 8000: HTTP API

### PostgreSQL
- **버전**: 16
- **역할**: stellar-core와 horizon 데이터 저장
- **포트**:
  - 5432: PostgreSQL (localhost만)

## 환경 변수

### 필수 변수
없음 (모든 변수에 기본값이 설정되어 있습니다)

### 선택 변수
- `NETWORK`: 네트워크 모드
  - `public` (기본값): 메인넷
  - `testnet`: 테스트넷
- `POSTGRES_USER`: PostgreSQL 사용자 (기본값: stellar)
- `POSTGRES_PASSWORD`: PostgreSQL 비밀번호 (기본값: stellarpassword)
- `HORIZON_PORT`: Horizon API 포트 (기본값: 8000)
- `INGEST`: Horizon 데이터 수집 활성화 (기본값: true)

## 데이터 저장

블록체인 데이터는 `/mnt/cryptocur-data/stellar` 디렉토리에 저장됩니다.

### 디스크 요구사항
- **메인넷**: 
  - stellar-core: ~200GB (2024년 기준)
  - horizon: ~500GB (전체 히스토리)
  - PostgreSQL: ~100GB
  - 권장 여유 공간: 1TB 이상
- **테스트넷**: ~50GB

## 네트워크 모드

### 메인넷 (기본값)
```bash
docker compose up -d
# 또는
NETWORK=public docker compose up -d
```

### 테스트넷
```bash
NETWORK=testnet docker compose up -d
```

## 노드 관리

### 로그 확인
```bash
# 전체 로그
docker compose logs -f

# stellar-core 로그만
docker compose logs -f stellar | grep -i stellar-core

# horizon 로그만
docker compose logs -f stellar | grep -i horizon

# PostgreSQL 로그
docker compose logs -f postgres
```

### 노드 중지
```bash
docker compose stop
```

### 노드 재시작
```bash
docker compose restart
```

### 노드 제거 (데이터 유지)
```bash
docker compose down
```

### 노드 제거 (데이터 삭제)
```bash
docker compose down -v
sudo rm -rf /mnt/cryptocur-data/stellar
```

## API 사용 예시

### stellar-core HTTP API
```bash
# 노드 정보
curl http://localhost:11626/info

# 피어 정보
curl http://localhost:11626/peers

# 메트릭
curl http://localhost:11626/metrics
```

### Horizon REST API
```bash
# 최신 원장(ledger) 조회
curl http://localhost:8000/ledgers?limit=1&order=desc

# 계정 조회
curl http://localhost:8000/accounts/{account_id}

# 트랜잭션 조회
curl http://localhost:8000/transactions?limit=10

# 자산 조회
curl http://localhost:8000/assets
```

## 동기화 시간

- **메인넷 전체 동기화**: 
  - stellar-core: 2-7일 (하드웨어 성능에 따라)
  - horizon ingestion: stellar-core 동기화 완료 후 1-3일
- **테스트넷**: 수 시간 ~ 1일

## 보안 주의사항

1. **포트 노출**: 
   - RPC 포트(11626, 8000)는 localhost로만 노출
   - P2P 포트(11625)만 외부에 노출
2. **PostgreSQL 비밀번호**: 
   - 기본 비밀번호를 반드시 변경하세요
3. **방화벽**: 
   - P2P 포트(11625)만 외부 개방
   - RPC 포트는 필요시 SSH 터널 사용
4. **정기 업데이트**: 
   - stellar-core와 horizon 최신 버전 유지

## 외부 접근 설정

외부에서 Horizon API에 접근하려면:

### 1) docker-compose.yml 포트 변경
```yaml
# 127.0.0.1:8000:8000 -> 0.0.0.0:8000:8000
- "8000:8000"
```

### 2) 방화벽 설정 (UFW)
```bash
# 특정 IP만 허용
sudo ufw allow from 203.0.113.10 to any port 8000

# 또는 전체 개방 (보안 위험)
sudo ufw allow 8000
```

### 3) 연결 테스트
```bash
# 외부 서버에서
curl http://<노드_공인IP>:8000/
```

## 문제 해결

### stellar-core가 시작되지 않는 경우
```bash
# 로그 확인
docker compose logs stellar

# 데이터베이스 재초기화
docker compose exec stellar rm /var/lib/stellar/core/.initialized
docker compose restart stellar
```

### horizon이 시작되지 않는 경우
```bash
# 데이터베이스 재초기화
docker compose exec stellar rm /var/lib/stellar/horizon/.initialized
docker compose restart stellar
```

### 디스크 공간 부족
```bash
# 사용량 확인
du -sh /mnt/cryptocur-data/stellar/*

# 오래된 PostgreSQL 로그 정리
docker compose exec postgres bash -c "find /var/lib/postgresql/data/log -name '*.log' -mtime +7 -delete"
```

## 상세 가이드

자세한 내용은 [docker-readme.md](./docker-readme.md)를 참고하세요.

## 참고 자료

- [Stellar 공식 문서](https://developers.stellar.org/)
- [stellar-core GitHub](https://github.com/stellar/stellar-core)
- [horizon GitHub](https://github.com/stellar/go/tree/master/services/horizon)
- [Stellar Dashboard](https://dashboard.stellar.org/)
