# RPC 인증 정보 중앙 관리 가이드

RPC 인증 정보(`rpcuser`, `rpcpassword`)를 한 곳에서만 관리하고 모든 곳에서 동일하게 사용하는 방법입니다.

## 🎯 목표

RPC 인증 정보를 **하나의 파일(또는 환경 변수)**에서만 관리하고, 다음 위치에서 동일하게 사용:
- `docker-compose.yml`의 `command` 옵션
- `docker-compose.yml`의 `healthcheck` 명령어
- 호스트에서 `bitcoin-cli` 실행 시

## 📋 방법 1: 환경 변수 사용 (권장)

### 설정 방법

#### 1단계: `.env` 파일 생성

```bash
cd chains/bitcoin/docker
cp env-example.txt .env
nano .env
```

`.env` 파일 내용:
```bash
BITCOIN_RPC_USER=bitcoin
BITCOIN_RPC_PASSWORD=your_secure_password_here
```

#### 2단계: docker-compose.yml에서 환경 변수 사용

`docker-compose.yml`은 이미 환경 변수를 사용하도록 설정되어 있습니다:

```yaml
environment:
  BITCOIN_RPC_USER: ${BITCOIN_RPC_USER:-bitcoin}
  BITCOIN_RPC_PASSWORD: ${BITCOIN_RPC_PASSWORD:-changeme}

command:
  - -rpcuser=${BITCOIN_RPC_USER:-bitcoin}
  - -rpcpassword=${BITCOIN_RPC_PASSWORD:-changeme}
```

**✅ 현재 상태**: 이미 환경 변수를 사용 중입니다.

#### 3단계: 헬스체크에서 환경 변수 사용

`docker-compose.yml`의 `healthcheck`도 환경 변수를 사용하도록 설정되어 있습니다:

```yaml
healthcheck:
  test: ["CMD-SHELL", "bitcoin-cli -rpccookiefile=/home/bitcoin/.bitcoin/.cookie getblockchaininfo 2>/dev/null || bitcoin-cli -rpcuser=${BITCOIN_RPC_USER} -rpcpassword=${BITCOIN_RPC_PASSWORD} getblockchaininfo || exit 1"]
```

**설명**:
- 먼저 쿠키 파일 시도 (가장 안전)
- 쿠키 파일이 없으면 환경 변수 사용

### 사용 방법

```bash
# .env 파일 사용 (docker-compose가 자동으로 읽음)
docker-compose up -d

# 또는 환경 변수로 직접 설정
export BITCOIN_RPC_USER=bitcoin
export BITCOIN_RPC_PASSWORD=your_password
docker-compose up -d

# 호스트에서 bitcoin-cli 사용 시
bitcoin-cli -rpcuser=${BITCOIN_RPC_USER} -rpcpassword=${BITCOIN_RPC_PASSWORD} getblockchaininfo
```

## 📋 방법 2: 쿠키 파일 사용 (가장 권장)

### 작동 원리

Bitcoin Core는 RPC 서버가 활성화되면 자동으로 `.cookie` 파일을 생성합니다:
- 위치: `/home/bitcoin/.bitcoin/.cookie`
- 형식: 자동 생성된 사용자명과 비밀번호가 포함됨
- 장점: 비밀번호를 명령줄에 노출하지 않음

### 설정 방법

#### 헬스체크에서 쿠키 파일 사용

```yaml
healthcheck:
  test: ["CMD-SHELL", "bitcoin-cli -rpccookiefile=/home/bitcoin/.bitcoin/.cookie getblockchaininfo || exit 1"]
```

**✅ 현재 docker-compose.yml**: 쿠키 파일을 우선 사용하도록 설정됨

#### 호스트에서 쿠키 파일 사용

```bash
# 쿠키 파일 경로 확인
docker exec bitcoin-node ls -la /home/bitcoin/.bitcoin/.cookie

# 쿠키 파일을 호스트로 복사 (선택사항)
docker cp bitcoin-node:/home/bitcoin/.bitcoin/.cookie ~/.bitcoin/.cookie

# 쿠키 파일 사용
bitcoin-cli -rpccookiefile=~/.bitcoin/.cookie getblockchaininfo
```

### 장점

- ✅ 가장 안전: 비밀번호가 명령줄에 노출되지 않음
- ✅ 자동 생성: bitcoind가 자동으로 생성
- ✅ 단순함: 인증 정보 관리 불필요
- ✅ 권장 방법: Bitcoin Core 공식 권장

## 📋 방법 3: bitcoin.conf 파일 사용

### 설정 방법

`bitcoin.conf` 파일에 RPC 인증 정보를 설정하고, 명령줄 옵션 제거:

#### bitcoin.conf
```conf
rpcuser=bitcoin
rpcpassword=your_secure_password
```

#### docker-compose.yml
```yaml
command:
  - bitcoind
  - -printtoconsole
  - -txindex=1
  - -dbcache=4500
  - -server=1
  # RPC 인증 정보는 bitcoin.conf에서 읽음
  # -rpcuser와 -rpcpassword 옵션 제거
```

#### 헬스체크
```yaml
healthcheck:
  # bitcoin-cli는 bitcoin.conf를 자동으로 읽음
  test: ["CMD-SHELL", "bitcoin-cli getblockchaininfo || exit 1"]
```

### 장점

- ✅ 설정 파일 중심 관리
- ✅ 명령줄 옵션 제거 가능

### 단점

- ⚠️ bitcoin.conf 파일 보안 관리 필요
- ⚠️ 설정 파일이 없으면 동작하지 않음

## 🔄 현재 권장 구성

### 현재 docker-compose.yml 구성 (개선됨)

```yaml
environment:
  # 환경 변수로 관리 (기본값 제공)
  BITCOIN_RPC_USER: ${BITCOIN_RPC_USER:-bitcoin}
  BITCOIN_RPC_PASSWORD: ${BITCOIN_RPC_PASSWORD:-changeme}

command:
  # 환경 변수 사용
  - -rpcuser=${BITCOIN_RPC_USER:-bitcoin}
  - -rpcpassword=${BITCOIN_RPC_PASSWORD:-changeme}

healthcheck:
  # 쿠키 파일 우선, 없으면 환경 변수 사용
  test: ["CMD-SHELL", "bitcoin-cli -rpccookiefile=/home/bitcoin/.bitcoin/.cookie getblockchaininfo 2>/dev/null || bitcoin-cli -rpcuser=${BITCOIN_RPC_USER} -rpcpassword=${BITCOIN_RPC_PASSWORD} getblockchaininfo || exit 1"]
```

### 장점

1. **환경 변수로 중앙 관리**: `.env` 파일에서 한 번만 설정
2. **쿠키 파일 우선 사용**: 보안성 향상
3. **환경 변수 폴백**: 쿠키 파일이 없어도 동작
4. **유연성**: 환경 변수 또는 `.env` 파일로 관리 가능

## 📝 사용 예시

### .env 파일 사용

```bash
# .env 파일 생성
cat > .env <<EOF
BITCOIN_RPC_USER=bitcoin
BITCOIN_RPC_PASSWORD=MySecurePassword123!
EOF

# docker-compose가 자동으로 .env 파일 읽음
docker-compose up -d
```

### 환경 변수 직접 사용

```bash
export BITCOIN_RPC_USER=bitcoin
export BITCOIN_RPC_PASSWORD=MySecurePassword123!
docker-compose up -d
```

### 호스트에서 bitcoin-cli 사용

```bash
# 방법 1: 환경 변수 사용
export BITCOIN_RPC_USER=bitcoin
export BITCOIN_RPC_PASSWORD=MySecurePassword123!
bitcoin-cli -rpcuser=${BITCOIN_RPC_USER} -rpcpassword=${BITCOIN_RPC_PASSWORD} -rpcport=8332 getblockchaininfo

# 방법 2: 직접 입력 (보안 주의)
bitcoin-cli -rpcuser=bitcoin -rpcpassword=MySecurePassword123! -rpcport=8332 getblockchaininfo
```

## 🔒 보안 권장사항

1. **강력한 비밀번호 사용**: 최소 16자, 대소문자, 숫자, 특수문자 포함
2. **.env 파일 권한**: `chmod 600 .env` (소유자만 읽기 가능)
3. **쿠키 파일 사용**: 가능하면 쿠키 파일 방식 사용
4. **.env 파일은 Git에 커밋하지 않기**: `.gitignore`에 추가

## 📚 참고사항

### 환경 변수 우선순위

1. `docker-compose.yml`의 `environment` 섹션
2. `.env` 파일
3. 호스트 환경 변수
4. 기본값 (예: `-bitcoin`)

### Docker Compose 환경 변수 참조

- `${VARIABLE}`: 환경 변수 필수
- `${VARIABLE:-default}`: 환경 변수가 없으면 기본값 사용 (현재 사용 중)
- `${VARIABLE-default}`: 환경 변수가 빈 문자열이면 기본값 사용

### bitcoin-cli 인증 방법 우선순위

1. 쿠키 파일 (`-rpccookiefile`)
2. 명령줄 옵션 (`-rpcuser`, `-rpcpassword`)
3. bitcoin.conf 파일
4. 환경 변수

## 결론

**현재 권장 방법**: 환경 변수 + 쿠키 파일 조합

- `.env` 파일에서 RPC 인증 정보 관리
- `docker-compose.yml`에서 환경 변수 참조
- 헬스체크는 쿠키 파일 우선 사용 (보안)

이렇게 하면 **한 곳(.env 파일)**에서만 관리하고, 모든 곳에서 일관되게 사용할 수 있습니다.
