# Stellar (XLM) 노드 설치 가이드

Stellar 전체 노드(stellar-core + horizon)를 설치하는 방법입니다.

## 설치 방법

### Docker (권장)
Docker를 사용한 설치 방법은 [docker/README.md](./docker/README.md)를 참고하세요.

**장점:**
- 간편한 설치 및 관리
- 일관된 환경 제공
- 쉬운 업데이트 및 롤백
- 호스트 시스템과 격리

### Localhost
호스트에 직접 설치하는 방법은 [localhost/README.md](./localhost/README.md)를 참고하세요.

**장점:**
- 더 나은 성능
- 직접적인 시스템 제어
- 리소스 최적화 가능

## Stellar 노드 구성

### stellar-core
- 블록체인 코어 노드
- P2P 네트워크 참여
- 합의 및 트랜잭션 검증
- 포트: 11625 (P2P), 11626 (HTTP)

### horizon
- REST API 서버
- 블록체인 데이터 조회 인터페이스
- 개발자 친화적 API 제공
- 포트: 8000 (HTTP)

### PostgreSQL
- stellar-core와 horizon 데이터 저장
- 트랜잭션 히스토리, 계정 정보 등

## 시스템 요구사항

### 최소 사양
- CPU: 4 코어
- RAM: 8GB
- 디스크: 500GB SSD
- 네트워크: 100Mbps

### 권장 사양 (메인넷)
- CPU: 8+ 코어
- RAM: 16GB+
- 디스크: 1TB+ NVMe SSD
- 네트워크: 1Gbps

## 네트워크 선택

### Public Network (메인넷)
- 실제 거래가 이루어지는 네트워크
- 동기화 시간: 2-7일
- 디스크 요구사항: ~1TB

### Test Network (테스트넷)
- 개발 및 테스트용 네트워크
- 동기화 시간: 수 시간
- 디스크 요구사항: ~50GB

## 빠른 시작 (Docker)

```bash
# 저장소 클론
git clone <repository-url>
cd blockchain-node-guides/chains/stellar/docker

# 데이터 디렉토리 준비
sudo mkdir -p /mnt/cryptocur-data/stellar
sudo chown -R 1000:1000 /mnt/cryptocur-data/stellar

# 노드 시작 (메인넷)
docker compose up -d

# 로그 확인
docker compose logs -f
```

## API 사용 예시

### Horizon API
```bash
# 최신 원장 조회
curl http://localhost:8000/ledgers?limit=1&order=desc

# 계정 정보 조회
curl http://localhost:8000/accounts/GACCOUNT...

# 트랜잭션 조회
curl http://localhost:8000/transactions?limit=10
```

### stellar-core HTTP API
```bash
# 노드 정보
curl http://localhost:11626/info

# 피어 정보
curl http://localhost:11626/peers
```

## 참고 자료

- [Stellar 공식 문서](https://developers.stellar.org/)
- [stellar-core GitHub](https://github.com/stellar/stellar-core)
- [horizon GitHub](https://github.com/stellar/go/tree/master/services/horizon)
- [Stellar Dashboard](https://dashboard.stellar.org/)
- [Stellar Expert Explorer](https://stellar.expert/)

## 문제 해결

문제가 발생하면 다음을 확인하세요:

1. **로그 확인**: `docker compose logs -f`
2. **디스크 공간**: `df -h /mnt/cryptocur-data/stellar`
3. **네트워크 연결**: stellar-core가 피어에 연결되었는지 확인
4. **PostgreSQL 상태**: 데이터베이스가 정상적으로 실행 중인지 확인

자세한 문제 해결 방법은 [docker/README.md](./docker/README.md)의 "문제 해결" 섹션을 참고하세요.
