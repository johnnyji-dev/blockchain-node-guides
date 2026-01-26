# Stellar 노드 Docker 상세 가이드

이 문서는 Stellar 노드를 Docker로 운영하는 상세 가이드입니다.

## 목차

1. [아키텍처](#아키텍처)
2. [설치 및 설정](#설치-및-설정)
3. [네트워크 구성](#네트워크-구성)
4. [데이터 관리](#데이터-관리)
5. [모니터링](#모니터링)
6. [백업 및 복구](#백업-및-복구)
7. [성능 최적화](#성능-최적화)
8. [보안](#보안)
9. [문제 해결](#문제-해결)

## 아키텍처

### 컨테이너 구성

```
┌─────────────────────────────────────────┐
│         stellar-node (Container)         │
│  ┌────────────┐      ┌────────────┐    │
│  │stellar-core│◄────►│  horizon   │    │
│  │  (Port:    │      │  (Port:    │    │
│  │   11625,   │      │   8000)    │    │
│  │   11626)   │      │            │    │
│  └─────┬──────┘      └─────┬──────┘    │
└────────┼───────────────────┼────────────┘
         │                   │
         ▼                   ▼
┌────────────────────────────────────────┐
│    postgres (Container)                 │
│    stellar_core DB / stellar_horizon DB │
│    (Port: 5432)                         │
└────────────────────────────────────────┘
```

### 포트 매핑

| 서비스 | 내부 포트 | 호스트 포트 | 용도 |
|--------|-----------|-------------|------|
| stellar-core | 11625 | 11625 | P2P 네트워크 |
| stellar-core | 11626 | 127.0.0.1:11626 | HTTP API (관리) |
| horizon | 8000 | 127.0.0.1:8000 | REST API |
| postgres | 5432 | 127.0.0.1:5432 | 데이터베이스 |

## 설치 및 설정

### 1단계: 시스템 준비

#### 디스크 공간 확인
```bash
# 최소 1TB 이상 권장
df -h /mnt/cryptocur-data
```

#### 디렉토리 생성
```bash
sudo mkdir -p /mnt/cryptocur-data/stellar/{core,horizon,postgres}
sudo chown -R 1000:1000 /mnt/cryptocur-data/stellar
sudo chmod -R 755 /mnt/cryptocur-data/stellar
```

### 2단계: 환경 변수 설정

`.env` 파일 생성:

```bash
cat > .env << 'EOF'
# Network Configuration
NETWORK=public                    # public 또는 testnet

# PostgreSQL Configuration
POSTGRES_USER=stellar
POSTGRES_PASSWORD=changeme_strong_password_here

# Horizon Configuration
HORIZON_PORT=8000
INGEST=true

# Docker Build
GIT_VERSION=latest
EOF
```

**보안 주의:** `.env` 파일에 실제 비밀번호를 입력하고, 파일 권한을 제한하세요:

```bash
chmod 600 .env
```

### 3단계: 이미지 빌드

```bash
# 이미지 빌드 (최초 30-60분 소요)
docker compose build

# 또는 캐시 없이 빌드
docker compose build --no-cache
```

### 4단계: 컨테이너 실행

```bash
# 백그라운드로 실행
docker compose up -d

# 로그 확인
docker compose logs -f
```

## 네트워크 구성

### 메인넷 (Public Network)

**특징:**
- 실제 XLM 거래
- 완전한 동기화 필요 (2-7일)
- 디스크 요구사항: ~1TB

**설정:**
```bash
NETWORK=public docker compose up -d
```

### 테스트넷 (Test Network)

**특징:**
- 개발 및 테스트용
- 빠른 동기화 (수 시간)
- 디스크 요구사항: ~50GB

**설정:**
```bash
NETWORK=testnet docker compose up -d
```

## 데이터 관리

### 데이터 저장 위치

```
/mnt/cryptocur-data/stellar/
├── core/               # stellar-core 데이터
│   ├── buckets/        # 히스토리 버킷
│   └── .initialized    # 초기화 플래그
├── horizon/            # horizon 데이터
│   └── .initialized    # 초기화 플래그
└── postgres/           # PostgreSQL 데이터
    └── data/           # DB 파일들
```

### 디스크 사용량 확인

```bash
# 전체 사용량
du -sh /mnt/cryptocur-data/stellar/*

# 상세 사용량
du -h --max-depth=2 /mnt/cryptocur-data/stellar/
```

### 데이터 정리

```bash
# PostgreSQL 진공 청소
docker compose exec postgres psql -U stellar -d stellar_core -c "VACUUM FULL;"
docker compose exec postgres psql -U stellar -d stellar_horizon -c "VACUUM FULL;"

# 오래된 로그 삭제
find /mnt/cryptocur-data/stellar/core -name "*.log" -mtime +7 -delete
```

## 모니터링

### 컨테이너 상태 확인

```bash
# 컨테이너 목록
docker compose ps

# 리소스 사용량
docker stats stellar-node stellar-postgres

# 헬스체크 상태
docker inspect --format='{{.State.Health.Status}}' stellar-node
```

### stellar-core 모니터링

```bash
# 노드 정보
curl http://localhost:11626/info | jq

# 동기화 상태
curl http://localhost:11626/info | jq '.info.state'

# 피어 연결 수
curl http://localhost:11626/peers | jq 'length'

# 메트릭
curl http://localhost:11626/metrics
```

### horizon 모니터링

```bash
# API 상태
curl http://localhost:8000/ | jq

# 최신 원장
curl http://localhost:8000/ledgers?limit=1&order=desc | jq

# 헬스체크
curl http://localhost:8000/health

# ingestion 상태
curl http://localhost:8000/metrics | grep horizon_ingest
```

### 로그 확인

```bash
# 실시간 로그 (모든 서비스)
docker compose logs -f

# stellar-core 로그만
docker compose logs -f stellar | grep stellar-core

# horizon 로그만
docker compose logs -f stellar | grep horizon

# PostgreSQL 로그
docker compose logs -f postgres

# 최근 100줄
docker compose logs --tail=100 stellar

# 특정 시간 이후 로그
docker compose logs --since=1h stellar
```

## 백업 및 복구

### 데이터 백업

#### 전체 백업 (권장하지 않음 - 용량 큼)
```bash
# stellar-core와 horizon 데이터
sudo tar -czf stellar-backup-$(date +%Y%m%d).tar.gz \
  /mnt/cryptocur-data/stellar/core \
  /mnt/cryptocur-data/stellar/horizon
```

#### PostgreSQL 백업 (권장)
```bash
# stellar-core 데이터베이스
docker compose exec postgres pg_dump -U stellar stellar_core | \
  gzip > stellar_core_backup_$(date +%Y%m%d).sql.gz

# horizon 데이터베이스
docker compose exec postgres pg_dump -U stellar stellar_horizon | \
  gzip > stellar_horizon_backup_$(date +%Y%m%d).sql.gz
```

### 데이터 복구

#### PostgreSQL 복구
```bash
# 컨테이너 중지
docker compose stop stellar

# stellar-core DB 복구
gunzip < stellar_core_backup_20240101.sql.gz | \
  docker compose exec -T postgres psql -U stellar stellar_core

# horizon DB 복구
gunzip < stellar_horizon_backup_20240101.sql.gz | \
  docker compose exec -T postgres psql -U stellar stellar_horizon

# 컨테이너 재시작
docker compose start stellar
```

### 재동기화 (처음부터)

```bash
# 컨테이너 중지 및 제거
docker compose down

# 데이터 삭제
sudo rm -rf /mnt/cryptocur-data/stellar/core/*
sudo rm -rf /mnt/cryptocur-data/stellar/horizon/*

# 초기화 플래그 제거
sudo rm -f /mnt/cryptocur-data/stellar/core/.initialized
sudo rm -f /mnt/cryptocur-data/stellar/horizon/.initialized

# 재시작
docker compose up -d
```

## 성능 최적화

### PostgreSQL 최적화

`.env` 파일에 PostgreSQL 설정 추가:

```bash
# PostgreSQL 튜닝 (16GB RAM 기준)
POSTGRES_SHARED_BUFFERS=4GB
POSTGRES_EFFECTIVE_CACHE_SIZE=12GB
POSTGRES_MAINTENANCE_WORK_MEM=1GB
POSTGRES_CHECKPOINT_COMPLETION_TARGET=0.9
POSTGRES_WAL_BUFFERS=16MB
POSTGRES_DEFAULT_STATISTICS_TARGET=100
POSTGRES_RANDOM_PAGE_COST=1.1
POSTGRES_EFFECTIVE_IO_CONCURRENCY=200
POSTGRES_WORK_MEM=20MB
POSTGRES_MIN_WAL_SIZE=1GB
POSTGRES_MAX_WAL_SIZE=4GB
```

### Docker 리소스 제한

`docker-compose.yml`에서 리소스 제한 활성화:

```yaml
deploy:
  resources:
    limits:
      cpus: '8'
      memory: 16G
    reservations:
      cpus: '4'
      memory: 8G
```

적용:
```bash
docker compose up -d --force-recreate
```

### 디스크 I/O 최적화

```bash
# 파일 시스템 확인
df -Th /mnt/cryptocur-data

# SSD인 경우 TRIM 활성화
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer
```

## 보안

### 방화벽 설정

```bash
# UFW 설치
sudo apt install -y ufw

# 기본 정책
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH 허용
sudo ufw allow 22

# stellar-core P2P 포트
sudo ufw allow 11625

# 특정 IP에서만 API 접근 허용 (선택사항)
sudo ufw allow from 203.0.113.10 to any port 8000
sudo ufw allow from 203.0.113.10 to any port 11626

# 방화벽 활성화
sudo ufw enable
sudo ufw status numbered
```

### PostgreSQL 비밀번호 변경

```bash
# .env 파일 수정
nano .env
# POSTGRES_PASSWORD=new_strong_password

# 컨테이너 재생성
docker compose down
docker compose up -d
```

### 외부 API 노출 (주의)

외부에서 접근이 필요한 경우:

```yaml
# docker-compose.yml 수정
ports:
  # 127.0.0.1:8000:8000 -> 0.0.0.0:8000:8000
  - "0.0.0.0:8000:8000"
```

**보안 강화:**
- 방화벽으로 IP 화이트리스트 설정
- Nginx 리버스 프록시 + SSL 사용
- Rate limiting 적용

### 정기 업데이트

```bash
# 최신 코드 pull
git pull

# 이미지 재빌드
docker compose build --no-cache

# 컨테이너 재생성
docker compose up -d --force-recreate
```

## 문제 해결

### stellar-core가 시작되지 않음

**증상:** 컨테이너가 반복적으로 재시작됨

**확인:**
```bash
# 로그 확인
docker compose logs stellar | grep -i error

# 설정 파일 확인
docker compose exec stellar cat /opt/stellar/stellar-core.cfg

# 데이터베이스 연결 확인
docker compose exec stellar psql -h postgres -U stellar -d stellar_core -c "SELECT 1;"
```

**해결:**
```bash
# 데이터베이스 재초기화
docker compose exec stellar rm /var/lib/stellar/core/.initialized
docker compose restart stellar
```

### horizon이 시작되지 않음

**증상:** horizon이 실행되지 않거나 API 응답 없음

**확인:**
```bash
# 로그 확인
docker compose logs stellar | grep -i horizon

# stellar-core 연결 확인
curl http://localhost:11626/info

# 데이터베이스 확인
docker compose exec postgres psql -U stellar -l
```

**해결:**
```bash
# horizon 데이터베이스 재초기화
docker compose exec stellar rm /var/lib/stellar/horizon/.initialized
docker compose restart stellar
```

### 동기화가 느림

**증상:** 동기화 속도가 매우 느림 (시간당 수백 ledger)

**확인:**
```bash
# 디스크 I/O 확인
iostat -x 1 10

# 네트워크 연결 확인
docker compose exec stellar curl -I https://history.stellar.org

# 피어 연결 수 확인
curl http://localhost:11626/peers | jq 'length'
```

**해결:**
- SSD 사용 확인
- 네트워크 대역폭 확인
- PostgreSQL 설정 최적화
- 더 많은 CPU/RAM 할당

### 디스크 공간 부족

**증상:** 컨테이너가 중지되거나 오류 발생

**확인:**
```bash
# 디스크 사용량
df -h /mnt/cryptocur-data

# 디렉토리별 사용량
du -sh /mnt/cryptocur-data/stellar/*
```

**해결:**
```bash
# PostgreSQL 진공 청소
docker compose exec postgres psql -U stellar -d stellar_core -c "VACUUM FULL;"
docker compose exec postgres psql -U stellar -d stellar_horizon -c "VACUUM FULL;"

# 오래된 로그 삭제
find /mnt/cryptocur-data/stellar -name "*.log" -mtime +7 -delete

# 디스크 확장 (클라우드의 경우)
# 클라우드 콘솔에서 볼륨 크기 증가 후
sudo resize2fs /dev/sdX
```

### PostgreSQL 연결 오류

**증상:** `could not connect to server` 오류

**확인:**
```bash
# PostgreSQL 컨테이너 상태
docker compose ps postgres

# PostgreSQL 로그
docker compose logs postgres | tail -50

# 네트워크 확인
docker network inspect stellar-network
```

**해결:**
```bash
# PostgreSQL 재시작
docker compose restart postgres

# 대기 후 stellar 재시작
sleep 10
docker compose restart stellar
```

### 메모리 부족

**증상:** 컨테이너가 OOM(Out of Memory)으로 종료됨

**확인:**
```bash
# 시스템 메모리
free -h

# 컨테이너 메모리 사용량
docker stats --no-stream

# OOM 로그
sudo journalctl -k | grep -i oom
```

**해결:**
- 시스템 메모리 증설
- PostgreSQL shared_buffers 감소
- Docker 메모리 제한 조정
- 스왑 공간 추가

## 유용한 명령어 모음

### 컨테이너 관리
```bash
# 시작
docker compose up -d

# 중지
docker compose stop

# 재시작
docker compose restart

# 제거 (데이터 유지)
docker compose down

# 제거 (볼륨 포함)
docker compose down -v

# 강제 재생성
docker compose up -d --force-recreate

# 로그 실시간
docker compose logs -f

# 특정 서비스 재시작
docker compose restart stellar
```

### 디버깅
```bash
# 컨테이너 내부 접속
docker compose exec stellar bash

# stellar-core 명령 실행
docker compose exec stellar stellar-core --help

# PostgreSQL 접속
docker compose exec postgres psql -U stellar -d stellar_core

# 네트워크 확인
docker network ls
docker network inspect stellar-network
```

### 모니터링
```bash
# stellar-core 정보
curl http://localhost:11626/info | jq

# horizon API
curl http://localhost:8000/ledgers?limit=1 | jq

# 메트릭
curl http://localhost:11626/metrics
```

## 참고 자료

- [Stellar 공식 문서](https://developers.stellar.org/)
- [stellar-core GitHub](https://github.com/stellar/stellar-core)
- [horizon GitHub](https://github.com/stellar/go)
- [PostgreSQL 문서](https://www.postgresql.org/docs/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
