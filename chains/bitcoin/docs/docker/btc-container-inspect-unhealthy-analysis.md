# Docker Inspect 결과 분석

Bitcoin 노드 Docker 컨테이너의 inspect 결과 분석 및 문제점 해결 가이드입니다.

## 컨테이너 기본 정보

### 컨테이너 식별자
- **컨테이너 ID**: `861b90c428cd832e5651dc45005bace883aba30404b1d4112b254cbd26ebf68b`
- **컨테이너 이름**: `bitcoin-node`
- **이미지**: `docker_bitcoind` (Ubuntu 22.04 기반)
- **생성일**: 2026-01-12T06:19:06
- **마지막 시작**: 2026-01-12T06:30:57

### 실행 상태
- **Status**: `running` ✅ (정상 실행 중)
- **Running**: `true`
- **PID**: 2906920
- **재시작 횟수**: 20회

## ⚠️ 중요한 문제점: 헬스체크 실패

### 헬스체크 상태
- **상태**: `unhealthy` ❌
- **실패 횟수**: 9,699회
- **문제**: RPC 인증 실패

### 에러 메시지
```
error: Authorization failed: Incorrect rpcuser or rpcpassword
```

### 원인 분석
헬스체크가 다음 명령을 실행합니다:
```bash
bitcoin-cli getblockchaininfo
```

이 명령이 실패하는 이유는:
1. **bitcoin-cli가 RPC 인증 정보를 모름**
   - 헬스체크 명령어에 `-rpcuser`와 `-rpcpassword`가 포함되지 않음
   - bitcoin-cli는 기본적으로 쿠키 파일이나 인증 정보가 필요함

2. **설정 파일 충돌 가능성**
   - 명령줄 옵션과 마운트된 `bitcoin.conf` 파일의 설정이 다를 수 있음
   - bitcoin.conf에 다른 RPC 인증 정보가 있을 수 있음

### 해결 방법

#### 방법 1: 헬스체크 명령어 수정 (권장)

`docker-compose.yml`의 헬스체크를 다음과 같이 수정:

```yaml
healthcheck:
  test: ["CMD-SHELL", "bitcoin-cli -rpcuser=bitcoin -rpcpassword=changeme getblockchaininfo || exit 1"]
  interval: 60s
  timeout: 10s
  start_period: 300s
  retries: 3
```

#### 방법 2: 쿠키 파일 사용 (더 안전)

RPC 쿠키 파일을 사용하도록 헬스체크 수정:

```yaml
healthcheck:
  test: ["CMD-SHELL", "bitcoin-cli -rpccookiefile=/home/bitcoin/.bitcoin/.cookie getblockchaininfo || exit 1"]
  interval: 60s
  timeout: 10s
  start_period: 300s
  retries: 3
```

#### 방법 3: 헬스체크 비활성화 (임시 해결)

문제 해결 전까지 헬스체크를 비활성화:

```yaml
# healthcheck 섹션 주석 처리 또는 제거
```

## 실행 명령어 분석

컨테이너가 실행하는 명령어:

```bash
bitcoind \
  -printtoconsole \
  -txindex=1 \
  -dbcache=4500 \
  -server=1 \
  -rpcuser=bitcoin \
  -rpcpassword=changeme \
  -rpcbind=0.0.0.0 \
  -rpcallowip=127.0.0.1
```

### 각 옵션 의미

- `-printtoconsole`: 로그를 콘솔에 출력
- `-txindex=1`: 트랜잭션 인덱스 활성화 (약 10GB 추가 공간 필요)
- `-dbcache=4500`: 데이터베이스 캐시 4.5GB (RAM 필요)
- `-server=1`: RPC 서버 활성화
- `-rpcuser=bitcoin`: RPC 사용자명
- `-rpcpassword=changeme`: RPC 비밀번호 (⚠️ 보안 주의!)
- `-rpcbind=0.0.0.0`: 모든 인터페이스에서 RPC 수신
- `-rpcallowip=127.0.0.1`: 로컬호스트만 RPC 접근 허용

### 보안 주의사항
⚠️ **`-rpcpassword=changeme`는 기본 비밀번호입니다. 반드시 변경하세요!**

## 포트 설정

### 포트 바인딩
- **8333/tcp** (P2P 네트워크)
  - 호스트: 모든 인터페이스 (`0.0.0.0:8333`)
  - IPv6: `::8333`
  - 목적: Bitcoin 네트워크와 P2P 통신

- **8332/tcp** (RPC)
  - 호스트: 로컬호스트만 (`127.0.0.1:8332`)
  - 목적: RPC 명령 실행
  - ✅ 보안: 로컬호스트만 접근 가능 (안전)

### 포트 접근 확인
```bash
# P2P 포트 확인
netstat -tlnp | grep 8333

# RPC 포트 확인
netstat -tlnp | grep 8332
```

## 볼륨 마운트

### 1. 데이터 디렉토리
```yaml
Source: /mnt/cryptocur-data/bitcoin
Destination: /home/bitcoin/.bitcoin
Mode: rw (읽기/쓰기)
```

**의미**: 
- 블록체인 데이터가 호스트의 `/mnt/cryptocur-data/bitcoin`에 저장됨
- 컨테이너를 삭제해도 데이터는 유지됨
- 여러 컨테이너가 같은 데이터를 공유할 수 있음

### 2. 설정 파일
```yaml
Source: /home/ubuntu/blockchain-node-guides/chains/bitcoin/docker/bitcoin.conf
Destination: /home/bitcoin/.bitcoin/bitcoin.conf
Mode: ro (읽기 전용)
```

**의미**:
- 호스트의 `bitcoin.conf` 파일이 컨테이너로 마운트됨
- 읽기 전용이므로 컨테이너 내부에서 수정 불가
- 호스트에서 설정 파일을 수정하면 재시작 시 반영됨

### 볼륨 확인 명령어
```bash
# 마운트된 볼륨 확인
docker inspect bitcoin-node | grep -A 10 Mounts

# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/bitcoin
```

## 네트워크 설정

### 네트워크 정보
- **네트워크 이름**: `docker_bitcoin-network`
- **네트워크 드라이버**: `bridge`
- **컨테이너 IP**: `172.21.0.2/16`
- **게이트웨이**: `172.21.0.1`
- **DNS 이름**: `bitcoin-node`, `bitcoind`

### 네트워크 확인
```bash
# 네트워크 정보 확인
docker network inspect docker_bitcoin-network

# 컨테이너 IP 확인
docker inspect bitcoin-node | grep IPAddress
```

## 환경 변수

컨테이너에 설정된 환경 변수:

```bash
BITCOIN_RPC_USER=bitcoin
BITCOIN_RPC_PASSWORD=changeme
BITCOIN_VERSION=26.0
BITCOIN_DATA_DIR=/home/bitcoin/.bitcoin
BITCOIN_USER=bitcoin
DEBIAN_FRONTEND=noninteractive
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

**참고**: 환경 변수는 명령줄 옵션과 함께 사용되지만, 명령줄 옵션이 우선순위가 높습니다.

## 리소스 사용량

### 현재 설정
- **CPU 제한**: 없음 (무제한)
- **메모리 제한**: 없음 (무제한)
- **ShmSize**: 64MB

### 권장 리소스 제한

`docker-compose.yml`에 추가 권장:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
    reservations:
      cpus: '2'
      memory: 4G
```

## 재시작 정책

- **정책**: `unless-stopped`
- **의미**: 
  - 컨테이너가 정상 종료되면 자동 재시작 안 함
  - 비정상 종료되면 자동 재시작
  - Docker 데몬 재시작 시 컨테이너도 자동 시작
- **재시작 횟수**: 제한 없음 (MaximumRetryCount: 0)

## 로그 파일 위치

```bash
/var/snap/docker/common/var-lib-docker/containers/861b90c428cd.../861b90c428cd...-json.log
```

**로그 확인 방법**:
```bash
# Docker 로그 확인 (권장)
docker logs bitcoin-node

# 실시간 로그 확인
docker logs -f bitcoin-node

# 최근 100줄 확인
docker logs --tail=100 bitcoin-node
```

## 파일 시스템

### 저장소 드라이버
- **드라이버**: `overlay2`
- **LowerDir**: 여러 레이어로 구성된 이미지 레이어
- **MergedDir**: 마운트된 최종 디렉토리
- **UpperDir**: 컨테이너에서 변경된 파일

## 보안 설정

### 사용자
- **실행 사용자**: `bitcoin` (비root 사용자) ✅
- **Privileged**: `false` ✅ (권한 상승 없음)

### 네트워크
- **NetworkMode**: `docker_bitcoin-network` (격리된 네트워크) ✅
- **RPC 포트**: 로컬호스트만 허용 ✅

### 마스킹된 경로
보안을 위해 다음 경로들이 마스킹됨:
- `/proc/kcore`
- `/proc/keys`
- `/sys/firmware`
- 등등...

## 문제 해결 체크리스트

### 헬스체크 실패 해결
- [ ] `docker-compose.yml`의 헬스체크에 RPC 인증 정보 추가
- [ ] 또는 `bitcoin.conf` 파일 확인 (RPC 인증 정보 일치 여부)
- [ ] `bitcoin-cli` 명령어가 올바른 인증 정보로 실행되는지 확인

### 설정 파일 확인
```bash
# 설정 파일 확인
cat /home/ubuntu/blockchain-node-guides/chains/bitcoin/docker/bitcoin.conf

# 컨테이너 내부 설정 파일 확인
docker exec bitcoin-node cat /home/bitcoin/.bitcoin/bitcoin.conf
```

### RPC 연결 테스트
```bash
# 컨테이너 내부에서 테스트
docker exec bitcoin-node bitcoin-cli -rpcuser=bitcoin -rpcpassword=changeme getblockchaininfo

# 호스트에서 테스트 (포트가 노출된 경우)
bitcoin-cli -rpcuser=bitcoin -rpcpassword=changeme -rpcport=8332 -rpcconnect=127.0.0.1 getblockchaininfo
```

## 권장 조치사항

1. **즉시 조치**
   - [ ] 헬스체크 명령어에 RPC 인증 정보 추가
   - [ ] `bitcoin.conf` 파일의 RPC 비밀번호 변경 (보안 강화)

2. **보안 강화**
   - [ ] 기본 비밀번호 `changeme`를 강력한 비밀번호로 변경
   - [ ] `bitcoin.conf` 파일 권한 설정 (600 권한 권장)

3. **모니터링**
   - [ ] 헬스체크 상태 모니터링
   - [ ] 로그 파일 정기 확인
   - [ ] 리소스 사용량 모니터링

## 추가 정보

### 컨테이너 재시작
```bash
# 컨테이너 재시작
docker restart bitcoin-node

# docker-compose 사용
docker-compose restart
```

### 컨테이너 로그 확인
```bash
# 전체 로그
docker logs bitcoin-node

# 마지막 100줄 + 실시간
docker logs -f --tail=100 bitcoin-node

# 특정 시간 이후 로그
docker logs --since 1h bitcoin-node
```

### 컨테이너 상태 확인
```bash
# 상태 확인
docker ps | grep bitcoin-node

# 상세 정보 확인
docker inspect bitcoin-node

# 리소스 사용량 확인
docker stats bitcoin-node
```
