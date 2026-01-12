# Ethereum 노드 Docker 가이드

Docker를 사용하여 Geth 노드를 실행하는 방법입니다.

## 목차
- [빠른 시작](#빠른-시작)
- [Dockerfile 설명](#dockerfile-설명)
- [docker-compose 사용](#docker-compose-사용)
- [설정 파일](#설정-파일)
- [데이터 관리](#데이터-관리)
- [문제 해결](#문제-해결)

## 빠른 시작

### 1. 설정 파일 준비

```bash
# 설정 파일 예제 복사
cp geth.toml.example geth.toml

# 설정 파일 편집 (선택사항)
nano geth.toml
# 필요에 따라 설정 조정
```

### 2. Docker Compose로 실행

```bash
# 이미지 빌드 및 컨테이너 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 컨테이너 상태 확인
docker-compose ps
```

### 3. 노드 상태 확인

```bash
# 컨테이너 내부에서 실행
docker-compose exec geth geth attach --exec 'eth.syncing'

# 동기화 상태 확인
docker-compose exec geth geth attach --exec 'eth.blockNumber'

# 피어 연결 수 확인
docker-compose exec geth geth attach --exec 'net.peerCount'
```

## Dockerfile 설명

### 기본 구조
- **베이스 이미지**: Ubuntu 22.04 LTS
- **Geth 버전**: 1.13.15 (환경 변수로 변경 가능)
- **사용자**: 비root 사용자(ethereum)로 실행
- **포트**: 30303 (P2P TCP/UDP), 8545 (HTTP-RPC), 8546 (WebSocket-RPC)

### 주요 특징
- 공식 Geth 바이너리 사용
- 보안을 위한 비root 사용자 실행
- 헬스체크 포함
- 볼륨 마운트를 통한 데이터 영구 저장

## docker-compose 사용

### 환경 변수 설정

`.env` 파일을 생성하여 환경 변수를 설정할 수 있습니다:

```bash
# .env 파일
ETHEREUM_DATA_PATH=/path/to/ethereum/data
ETHEREUM_NETWORK=mainnet
```

### 데이터 디렉토리 설정

기본적으로 `/mnt/cryptocur-data/ethereum` 디렉토리를 사용합니다. 다른 경로를 사용하려면:

```bash
# docker-compose.yml에서 직접 수정
```

### 리소스 제한

`docker-compose.yml`에서 리소스 제한을 조정할 수 있습니다:

```yaml
deploy:
  resources:
    limits:
      cpus: '8'      # 최대 CPU
      memory: 16G     # 최대 메모리
    reservations:
      cpus: '4'      # 최소 CPU
      memory: 8G     # 최소 메모리
```

## 설정 파일

### 설정 파일 위치

- **컨테이너 내부**: `/home/ethereum/.ethereum/geth.toml`
- **호스트**: `./geth.toml` (docker-compose.yml에서 마운트)

### 주요 설정 옵션

#### RPC 보안 설정
```toml
[HTTP]
Addr = "127.0.0.1"  # 로컬호스트만 허용 (권장)
APIs = ["eth", "net", "web3"]  # 필요한 API만 활성화

[WS]
Addr = "127.0.0.1"  # 로컬호스트만 허용
```

#### 성능 최적화
```toml
# 캐시 크기 (메모리 사용량 증가)
Cache = 4096

# 동기화 모드
SyncMode = "snap"  # 빠른 동기화 (권장)
```

## 데이터 관리

### 데이터 백업

```bash
# 컨테이너 중지
docker-compose stop

# 데이터 디렉토리 백업
tar -czf ethereum-backup-$(date +%Y%m%d).tar.gz /mnt/cryptocur-data/ethereum

# 컨테이너 재시작
docker-compose start
```

### 데이터 복원

```bash
# 컨테이너 중지
docker-compose stop

# 백업에서 복원
tar -xzf ethereum-backup-YYYYMMDD.tar.gz -C /mnt/cryptocur-data/

# 컨테이너 재시작
docker-compose start
```

### 데이터 디렉토리 크기 확인

```bash
# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/ethereum

# 또는 컨테이너 내부에서
docker-compose exec geth du -sh /home/ethereum/.ethereum
```

## 문제 해결

### 컨테이너가 시작되지 않음

```bash
# 로그 확인
docker-compose logs geth

# 컨테이너 상태 확인
docker-compose ps -a

# 포트 충돌 확인
netstat -tlnp | grep 30303
netstat -tlnp | grep 8545
netstat -tlnp | grep 8546
```

### 동기화 문제

```bash
# 블록체인 정보 확인
docker-compose exec geth geth attach --exec 'eth.syncing'

# 최신 블록 번호 확인
docker-compose exec geth geth attach --exec 'eth.blockNumber'

# 재동기화 (시간이 오래 걸림)
docker-compose stop
docker-compose run --rm geth geth --mainnet --datadir=/home/ethereum/.ethereum --syncmode=snap
docker-compose start
```

### RPC 연결 실패

```bash
# RPC 설정 확인
docker-compose exec geth cat /home/ethereum/.ethereum/geth.toml | grep -A 5 HTTP

# RPC 테스트
docker-compose exec geth geth attach --exec 'net.version'
```

### 디스크 공간 부족

```bash
# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/ethereum

# 불필요한 로그 파일 정리
docker-compose exec geth find /home/ethereum/.ethereum -name "*.log" -delete
```

## 유용한 명령어

### 컨테이너 관리
```bash
# 컨테이너 시작
docker-compose up -d

# 컨테이너 중지
docker-compose stop

# 컨테이너 재시작
docker-compose restart

# 컨테이너 제거 (데이터는 유지됨)
docker-compose down

# 컨테이너 및 볼륨 제거 (주의: 데이터 삭제됨)
docker-compose down -v
```

### 로그 확인
```bash
# 실시간 로그
docker-compose logs -f

# 최근 100줄
docker-compose logs --tail=100

# 특정 시간 이후 로그
docker-compose logs --since 1h
```

### Geth Console 사용
```bash
# Geth 콘솔 접속
docker-compose exec geth geth attach

# 명령어 직접 실행
docker-compose exec geth geth attach --exec 'eth.blockNumber'
docker-compose exec geth geth attach --exec 'net.peerCount'
docker-compose exec geth geth attach --exec 'eth.syncing'
```

## 보안 권장사항

1. **RPC 접근 제한**: HTTP-RPC와 WebSocket-RPC는 localhost로만 노출
2. **API 제한**: admin, debug API는 필요한 경우에만 활성화
3. **방화벽**: 호스트 방화벽 설정
4. **정기 업데이트**: Geth 최신 버전 유지
5. **백업**: 정기적인 데이터 백업

## 추가 리소스

- [Geth 공식 문서](https://geth.ethereum.org/docs)
- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
