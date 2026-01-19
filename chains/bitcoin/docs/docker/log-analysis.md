# Bitcoin 노드 로그 분석 가이드

## 📊 로그 분석 결과

### ✅ 정상 동작 중인 항목

#### 1. 노드 시작 및 초기화
- **Bitcoin Core 버전**: v26.0.0 (정상)
- **데이터 디렉토리**: `/home/bitcoin/.bitcoin` (정상)
- **설정 파일**: `/home/bitcoin/.bitcoin/bitcoin.conf` (정상 로드)

#### 2. LevelDB 데이터베이스
- **Block Index**: 성공적으로 열림
- **Chainstate**: 성공적으로 열림
- **Transaction Index**: 성공적으로 열림
- **Block Filter Index**: 성공적으로 열림

#### 3. 블록체인 동기화
- **현재 블록 높이**: 932873 (최신)
- **동기화 상태**: 완료 (`progress=1.000000`)
- **Initial Block Download (IBD)**: 완료
- **블록 검증**: 성공 (6개 블록 검증 완료)

#### 4. 네트워크 연결
- **P2P 포트**: 8333 (정상 바인딩)
- **Tor 포트**: 8334 (정상 바인딩)
- **피어 연결**: 정상 (여러 피어와 연결됨)
- **DNS 시드**: P2P 피어가 있어서 스킵됨 (정상)

#### 5. 인덱스 활성화
- **Transaction Index (txindex)**: 활성화됨 (height 932868)
- **Basic Block Filter Index**: 활성화됨 (height 932868)

### ⚠️ 문제점

#### 1. RPC 인증 실패 (반복 발생)

**에러 메시지**:
```
ThreadRPCServer incorrect password attempt from 127.0.0.1:51724
ThreadRPCServer incorrect password attempt from 127.0.0.1:42418
ThreadRPCServer incorrect password attempt from 127.0.0.1:56424
ThreadRPCServer incorrect password attempt from 127.0.0.1:47596
```

**발생 시간**: 약 1분마다 반복

**원인 분석**:
- 헬스체크가 잘못된 RPC 인증 정보를 사용하고 있음
- 환경 변수가 헬스체크 명령어에 제대로 전달되지 않음
- 쿠키 파일이 아직 생성되지 않았거나 접근 불가

**영향**:
- 헬스체크가 실패하여 컨테이너가 `unhealthy` 상태로 표시될 수 있음
- 보안 로그에 불필요한 실패 시도 기록

#### 2. RPC 바인딩 경고

**메시지**:
```
Binding RPC on address 0.0.0.0 port 8332 failed.
```

**원인**:
- IPv6 바인딩 시도 후 실패 (정상적인 동작일 수 있음)
- 또는 이전 프로세스가 포트를 점유 중

**영향**:
- RPC는 여전히 작동하지만 일부 인터페이스에서 바인딩 실패

#### 3. Mempool 파일 로드 실패

**메시지**:
```
Failed to open mempool file from disk. Continuing anyway.
```

**원인**:
- 이전 세션의 mempool 파일이 손상되었거나 없음
- 정상적인 동작 (새로운 mempool로 시작)

**영향**:
- 없음 (정상 동작)

## 🔍 상세 분석

### 시작 과정 (02:49:51)

1. **초기화**:
   - Bitcoin Core v26.0.0 시작
   - 데이터 디렉토리 확인
   - 설정 파일 로드

2. **LevelDB 열기**:
   - Block Index: 성공
   - Chainstate: 성공
   - Transaction Index: 성공
   - Block Filter Index: 성공

3. **블록체인 로드**:
   - 마지막 블록 파일: 5348
   - 최신 블록: 932838
   - 검증 진행: 6개 블록 검증 완료

### 동기화 과정 (02:50:02 - 02:50:24)

1. **네트워크 시작**:
   - P2P 포트 바인딩: 성공
   - Tor 포트 바인딩: 성공
   - 피어 연결 시작

2. **블록 동기화**:
   - 932838 → 932873 (35개 블록 동기화)
   - 약 22초 소요
   - 동기화 완료: `progress=1.000000`

3. **인덱스 활성화**:
   - Transaction Index: 활성화
   - Block Filter Index: 활성화

### 정상 운영 상태 (02:50:24 이후)

- 피어 연결: 정상 (여러 피어와 연결)
- 블록체인: 최신 상태 유지
- 네트워크: 정상 동작

## 🔧 해결 방법

### 문제 1: RPC 인증 실패 해결

#### 원인
헬스체크 명령어에서 환경 변수가 제대로 전달되지 않음

#### 해결 방법 1: 쿠키 파일 사용 (권장)

현재 `docker-compose.yml`의 헬스체크는 이미 쿠키 파일을 우선 사용하도록 설정되어 있지만, 쿠키 파일이 생성되기 전에 헬스체크가 실행될 수 있습니다.

**해결책**: `start_period`를 늘리거나 쿠키 파일 생성 확인

```yaml
healthcheck:
  test: ["CMD-SHELL", "test -f /home/bitcoin/.bitcoin/.cookie && bitcoin-cli -rpccookiefile=/home/bitcoin/.bitcoin/.cookie getblockchaininfo || exit 1"]
  interval: 60s
  timeout: 10s
  start_period: 600s  # 10분으로 증가 (쿠키 파일 생성 대기)
  retries: 3
```

#### 해결 방법 2: 환경 변수 직접 사용

```yaml
healthcheck:
  test: ["CMD-SHELL", "bitcoin-cli -rpcuser=bitcoin -rpcpassword=changeme getblockchaininfo || exit 1"]
  interval: 60s
  timeout: 10s
  start_period: 300s
  retries: 3
```

**주의**: 비밀번호가 하드코딩되므로 보안상 권장하지 않음

#### 해결 방법 3: 헬스체크 스크립트 사용

`healthcheck.sh` 스크립트 생성 및 사용:

```yaml
healthcheck:
  test: ["CMD-SHELL", "/usr/local/bin/healthcheck.sh || exit 1"]
  interval: 60s
  timeout: 10s
  start_period: 300s
  retries: 3
```

### 문제 2: RPC 바인딩 경고

#### 해결 방법

IPv6 바인딩 실패는 정상일 수 있습니다. 무시해도 됩니다.

또는 `bitcoin.conf`에서 IPv6 비활성화:

```conf
# IPv6 비활성화 (선택사항)
rpcbind=127.0.0.1  # IPv4만 사용
```

### 문제 3: Mempool 파일 로드 실패

#### 해결 방법

정상적인 동작이므로 조치 불필요. 새로운 mempool로 시작됩니다.

## 📋 로그 주요 지표

### 성능 지표

- **블록 인덱스 로드 시간**: 10029ms (약 10초)
- **블록 동기화 시간**: 약 22초 (35개 블록)
- **캐시 사용량**: 약 29.5 MiB
- **트랜잭션 수**: 1,299,046,241개

### 네트워크 지표

- **피어 연결 수**: 여러 피어와 연결됨
- **P2P 포트**: 8333 (정상)
- **RPC 포트**: 8332 (정상, 일부 바인딩 실패)

### 데이터베이스 지표

- **Block Index**: 2.0 MiB
- **Transaction Index**: 562.2 MiB
- **Block Filter Index**: 492.0 MiB
- **Chainstate**: 8.0 MiB
- **UTXO Set**: 3435.8 MiB (메모리)

## ✅ 현재 상태 요약

### 정상 동작
- ✅ Bitcoin Core 노드 정상 실행
- ✅ 블록체인 동기화 완료 (최신 상태)
- ✅ 네트워크 연결 정상
- ✅ 모든 인덱스 활성화 및 정상 작동
- ✅ LevelDB 데이터베이스 정상

### 주의 필요
- ⚠️ RPC 인증 실패 (헬스체크 문제)
- ⚠️ RPC 바인딩 경고 (영향 없음)
- ⚠️ Mempool 파일 로드 실패 (정상 동작)

## 🎯 권장 조치사항

### 즉시 조치

1. **헬스체크 수정**:
   ```bash
   # docker-compose.yml 수정 후
   docker-compose down
   docker-compose up -d
   ```

2. **헬스체크 상태 확인**:
   ```bash
   docker inspect bitcoin-node | grep -A 10 Health
   ```

### 모니터링

1. **로그 모니터링**:
   ```bash
   docker-compose logs -f | grep -E "(error|Error|ERROR|incorrect password)"
   ```

2. **노드 상태 확인**:
   ```bash
   docker-compose exec bitcoind bitcoin-cli getblockchaininfo
   docker-compose exec bitcoind bitcoin-cli getnetworkinfo
   ```

## 📝 결론

**전체적인 상태**: ✅ **정상 동작 중**

Bitcoin 노드는 정상적으로 실행되고 있으며, 블록체인도 최신 상태로 동기화되어 있습니다. 

**유일한 문제**: RPC 인증 실패는 헬스체크 설정 문제로, 노드 자체의 기능에는 영향을 주지 않습니다. 헬스체크 설정을 수정하면 해결됩니다.

**권장 조치**: 헬스체크 설정을 수정하여 RPC 인증 실패 로그를 제거하세요.
