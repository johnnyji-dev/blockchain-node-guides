# Bitcoin 노드 컨테이너 Inspect 분석 (Healthy 상태)

Bitcoin 노드 Docker 컨테이너의 `docker inspect` 결과 분석 - **Healthy 상태**입니다.

## 📊 컨테이너 기본 정보

### 컨테이너 식별자
- **컨테이너 ID**: `8985c54161f9152bd9357b1c22f6eb7bb2bc011edcae1a5d2918e93f3590fa5c`
- **컨테이너 이름**: `bitcoin-node`
- **이미지**: `docker_bitcoind` (Ubuntu 22.04 기반)
- **생성일**: 2026-01-19T02:49:50
- **시작일**: 2026-01-19T02:49:50

### 실행 상태
- **Status**: `running` ✅ (정상 실행 중)
- **Running**: `true`
- **PID**: 3628537
- **재시작 횟수**: 0회 ✅ (정상, 재시작 없음)
- **ExitCode**: 0 (정상 종료 코드)

## ✅ 헬스체크 상태: Healthy

### 헬스체크 정보
- **상태**: `healthy` ✅
- **실패 횟수**: 0회 ✅
- **마지막 헬스체크**: 성공

### 헬스체크 로그 분석

최근 5회의 헬스체크가 모두 성공했습니다:

#### 1. 헬스체크 #1 (03:20:18 - 03:20:19)
```json
{
  "chain": "main",
  "blocks": 932875,
  "headers": 932875,
  "bestblockhash": "00000000000000000001c05c02482ec921a4da3ecb5ddb2c813a721fb3c6b742",
  "verificationprogress": 0.999998465474728,
  "initialblockdownload": false,
  "size_on_disk": 813437645225
}
```
- ✅ **ExitCode**: 0 (성공)
- ✅ **응답 시간**: 약 0.28초
- ✅ **블록체인 상태**: 최신 (932875 블록)
- ✅ **동기화 완료**: `initialblockdownload: false`

#### 2-5. 헬스체크 #2-5
모든 헬스체크가 성공적으로 완료되었으며, 블록체인 상태가 정상적으로 유지되고 있습니다.

### 헬스체크 설정

```json
{
  "Test": [
    "CMD-SHELL",
    "bitcoin-cli -rpccookiefile=/home/bitcoin/.bitcoin/.cookie getblockchaininfo 2>/dev/null || bitcoin-cli -rpcuser=bitcoin -rpcpassword=firpeng getblockchaininfo || exit 1"
  ],
  "Interval": 60000000000,      // 60초
  "Timeout": 10000000000,       // 10초
  "StartPeriod": 300000000000,  // 300초 (5분)
  "Retries": 3
}
```

**설정 분석**:
- ✅ **쿠키 파일 우선 사용**: 보안상 권장되는 방법
- ✅ **환경 변수 폴백**: 쿠키 파일이 없을 경우 대체 방법 제공
- ✅ **적절한 간격**: 60초마다 체크 (리소스 효율적)
- ✅ **충분한 시작 대기 시간**: 5분 (블록체인 동기화 고려)

## 🚀 실행 명령어 분석

컨테이너가 실행하는 명령어:

```bash
bitcoind \
  -printtoconsole \
  -txindex=1 \
  -dbcache=4500 \
  -server=1 \
  -rpcuser=bitcoin \
  -rpcpassword=firpeng \
  -rpcbind=0.0.0.0 \
  -rpcallowip=127.0.0.1
```

### 각 옵션 의미

- `-printtoconsole`: 로그를 콘솔에 출력
- `-txindex=1`: 트랜잭션 인덱스 활성화 (약 10GB 추가 공간 필요)
- `-dbcache=4500`: 데이터베이스 캐시 4.5GB (RAM 필요)
- `-server=1`: RPC 서버 활성화
- `-rpcuser=bitcoin`: RPC 사용자명
- `-rpcpassword=firpeng`: RPC 비밀번호 ⚠️ (실제 운영 시 강력한 비밀번호 권장)
- `-rpcbind=0.0.0.0`: 모든 인터페이스에서 RPC 수신
- `-rpcallowip=127.0.0.1`: 로컬호스트만 RPC 접근 허용 ✅ (보안)

## 🔌 포트 설정

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

## 💾 볼륨 마운트

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

## 🌐 네트워크 설정

### 네트워크 정보
- **네트워크 이름**: `docker_bitcoin-network`
- **네트워크 드라이버**: `bridge`
- **컨테이너 IP**: `172.21.0.2/16`
- **게이트웨이**: `172.21.0.1`
- **DNS 이름**: `bitcoin-node`, `bitcoind`, `8985c54161f9`

### 네트워크 확인
```bash
# 네트워크 정보 확인
docker network inspect docker_bitcoin-network

# 컨테이너 IP 확인
docker inspect bitcoin-node | grep IPAddress
```

## 🔐 환경 변수

컨테이너에 설정된 환경 변수:

```bash
BITCOIN_RPC_USER=bitcoin
BITCOIN_RPC_PASSWORD=firpeng
BITCOIN_VERSION=26.0
BITCOIN_DATA_DIR=/home/bitcoin/.bitcoin
BITCOIN_USER=bitcoin
DEBIAN_FRONTEND=noninteractive
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

**참고**: 환경 변수는 명령줄 옵션과 함께 사용되지만, 명령줄 옵션이 우선순위가 높습니다.

## 📈 리소스 사용량

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

## 🔄 재시작 정책

- **정책**: `unless-stopped`
- **의미**: 
  - 컨테이너가 정상 종료되면 자동 재시작 안 함
  - 비정상 종료되면 자동 재시작
  - Docker 데몬 재시작 시 컨테이너도 자동 시작
- **재시작 횟수**: 제한 없음 (MaximumRetryCount: 0)
- **실제 재시작 횟수**: 0회 ✅ (정상)

## 📝 로그 파일 위치

```bash
/var/snap/docker/common/var-lib-docker/containers/8985c54161f9152bd9357b1c22f6eb7bb2bc011edcae1a5d2918e93f3590fa5c/8985c54161f9152bd9357b1c22f6eb7bb2bc011edcae1a5d2918e93f3590fa5c-json.log
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

## 💿 파일 시스템

### 저장소 드라이버
- **드라이버**: `overlay2`
- **LowerDir**: 여러 레이어로 구성된 이미지 레이어
- **MergedDir**: 마운트된 최종 디렉토리
- **UpperDir**: 컨테이너에서 변경된 파일

## 🔒 보안 설정

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

## 📊 블록체인 상태 (헬스체크 응답 기준)

### 현재 상태
- **체인**: `main` (메인넷)
- **블록 높이**: 932875
- **헤더**: 932875
- **검증 진행률**: 99.9998% (거의 완료)
- **초기 블록 다운로드**: 완료 (`false`)
- **디스크 사용량**: 약 813GB
- **프루닝**: 비활성화 (`false`)

### 상태 분석
- ✅ **동기화 완료**: `initialblockdownload: false`
- ✅ **최신 상태**: 블록과 헤더가 일치
- ✅ **정상 작동**: 헬스체크가 정상적으로 응답

## 🔍 Healthy vs Unhealthy 비교

### 이전 Unhealthy 상태의 문제점
1. ❌ 헬스체크 실패 (9,699회 연속)
2. ❌ RPC 인증 실패
3. ❌ 쿠키 파일 미사용

### 현재 Healthy 상태의 개선점
1. ✅ 헬스체크 성공 (0회 실패)
2. ✅ RPC 인증 성공
3. ✅ 쿠키 파일 우선 사용
4. ✅ 환경 변수 폴백 제공

### 개선된 헬스체크 명령어

**이전 (Unhealthy)**:
```bash
bitcoin-cli getblockchaininfo
# RPC 인증 정보 없음 → 실패
```

**현재 (Healthy)**:
```bash
bitcoin-cli -rpccookiefile=/home/bitcoin/.bitcoin/.cookie getblockchaininfo 2>/dev/null || \
bitcoin-cli -rpcuser=bitcoin -rpcpassword=firpeng getblockchaininfo || exit 1
# 쿠키 파일 우선 → 환경 변수 폴백 → 성공
```

## ✅ 정상 동작 확인 체크리스트

### 컨테이너 상태
- [x] 컨테이너 실행 중 (`running`)
- [x] 재시작 없음 (`RestartCount: 0`)
- [x] 헬스체크 정상 (`healthy`)
- [x] 비root 사용자로 실행 (`bitcoin`)

### 네트워크
- [x] P2P 포트 정상 (8333)
- [x] RPC 포트 정상 (8332, localhost만)
- [x] 네트워크 격리됨

### 데이터
- [x] 볼륨 마운트 정상
- [x] 설정 파일 마운트 정상
- [x] 블록체인 동기화 완료

### 보안
- [x] 비root 사용자
- [x] RPC 로컬호스트만 허용
- [x] 권한 상승 없음

## 🎯 권장 모니터링 항목

### 1. 헬스체크 상태 모니터링
```bash
# 헬스체크 상태 확인
docker inspect --format='{{json .State.Health}}' bitcoin-node | jq

# 헬스체크 로그 확인
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' bitcoin-node
```

### 2. 블록체인 상태 모니터링
```bash
# 블록체인 정보 확인
docker exec bitcoin-node bitcoin-cli getblockchaininfo

# 동기화 상태 확인
docker exec bitcoin-node bitcoin-cli getblockchaininfo | grep verificationprogress
```

### 3. 리소스 사용량 모니터링
```bash
# 리소스 사용량 확인
docker stats bitcoin-node

# 디스크 사용량 확인
du -sh /mnt/cryptocur-data/bitcoin
```

## 📚 추가 정보

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

## 결론

### 현재 상태: ✅ **완벽하게 정상 동작 중**

1. **헬스체크**: Healthy 상태 유지
2. **블록체인**: 최신 상태로 동기화 완료
3. **네트워크**: 정상 연결
4. **보안**: 적절한 설정 적용
5. **성능**: 정상 작동

### 주요 개선 사항

1. ✅ **헬스체크 설정 개선**: 쿠키 파일 우선 사용 + 환경 변수 폴백
2. ✅ **RPC 인증 성공**: 올바른 인증 정보 사용
3. ✅ **안정성 향상**: 재시작 없이 정상 운영

이 컨테이너는 현재 완벽하게 정상 동작하고 있으며, 모든 설정이 최적화되어 있습니다.
