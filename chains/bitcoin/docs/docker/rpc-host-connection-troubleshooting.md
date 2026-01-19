# RPC 호스트 연결 문제 해결 가이드

Docker 컨테이너 내부에서는 RPC 명령어가 동작하지만, 호스트에서 동일한 명령어가 동작하지 않는 문제 해결 가이드입니다.

## 🔍 문제 증상

### 정상 동작 (컨테이너 내부)
```bash
# 컨테이너 내부에서 실행 - ✅ 성공
docker exec bitcoin-node curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:firpeng" \
  --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result'
```

### 문제 발생 (호스트에서)
```bash
# 호스트에서 실행 - ❌ 실패 (출력 없음)
curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:firpeng" \
  --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result'
```

## 🔎 원인 분석

### 주요 원인: `rpcallowip` 설정 문제

**현재 설정**:
```yaml
command:
  - -rpcbind=0.0.0.0
  - -rpcallowip=127.0.0.1
```

**문제점**:
1. **Docker 네트워크 격리**: 
   - 컨테이너 내부의 `127.0.0.1`과 호스트의 `127.0.0.1`은 **다른 네트워크**입니다
   - `rpcallowip=127.0.0.1`은 컨테이너 내부의 localhost만 허용
   - 호스트에서 접근할 때는 다른 IP로 인식됨

2. **Docker 포트 포워딩**:
   - 포트 매핑: `127.0.0.1:8332->8332/tcp`
   - 호스트의 `127.0.0.1:8332`는 Docker 네트워크를 통해 컨테이너로 전달됨
   - 하지만 bitcoind는 요청의 실제 소스 IP를 확인하여 `rpcallowip`와 비교
   - 호스트에서 오는 요청의 소스 IP는 Docker 네트워크의 게이트웨이 IP 또는 컨테이너 네트워크 IP

3. **네트워크 구조**:
   ```
   호스트 (127.0.0.1:8332)
     ↓ (포트 포워딩)
   Docker 네트워크 (172.21.0.1:8332)
     ↓
   컨테이너 (172.21.0.2:8332)
     ↓
   bitcoind (0.0.0.0:8332에서 수신)
   ```
   
   - 호스트에서 접근 시 실제 소스 IP는 `172.21.0.1` (게이트웨이) 또는 다른 Docker 네트워크 IP
   - `rpcallowip=127.0.0.1`은 이 IP를 허용하지 않음

## 🔧 해결 방법

### 방법 1: Docker 네트워크 IP 범위 허용 (권장)

`docker-compose.yml`의 command 섹션을 수정:

```yaml
command:
  - bitcoind
  - -printtoconsole
  - -txindex=1
  - -dbcache=4500
  - -server=1
  - -rpcuser=${BITCOIN_RPC_USER:-bitcoin}
  - -rpcpassword=${BITCOIN_RPC_PASSWORD:-changeme}
  - -rpcbind=0.0.0.0
  - -rpcallowip=127.0.0.1      # 컨테이너 내부 접근
  - -rpcallowip=172.21.0.0/16  # Docker 네트워크 허용 (게이트웨이 포함)
```

**또는 더 넓은 범위**:
```yaml
  - -rpcallowip=172.16.0.0/12  # Docker 기본 네트워크 범위
```

### 방법 2: 호스트 네트워크 IP 허용

호스트의 실제 IP 주소를 확인하고 허용:

```bash
# 호스트 IP 확인
hostname -I

# 또는
ip addr show | grep "inet " | grep -v 127.0.0.1
```

예를 들어 호스트 IP가 `192.168.1.100`인 경우:

```yaml
command:
  - -rpcallowip=127.0.0.1
  - -rpcallowip=192.168.1.100
```

### 방법 3: 모든 로컬 네트워크 허용 (개발 환경만)

**⚠️ 주의**: 보안상 프로덕션 환경에서는 권장하지 않습니다.

```yaml
command:
  - -rpcbind=0.0.0.0
  - -rpcallowip=127.0.0.1
  - -rpcallowip=10.0.0.0/8      # 사설 IP 범위
  - -rpcallowip=172.16.0.0/12    # Docker 네트워크
  - -rpcallowip=192.168.0.0/16   # 사설 IP 범위
```

### 방법 4: bitcoin.conf 파일 수정

`bitcoin.conf` 파일이 마운트되어 있다면, 파일에서 직접 수정:

```conf
# RPC 설정
server=1
rpcbind=0.0.0.0
rpcport=8332
rpcuser=bitcoin
rpcpassword=firpeng
rpcallowip=127.0.0.1
rpcallowip=172.21.0.0/16    # Docker 네트워크 추가
```

## 🔍 진단 방법

### 1. Docker 네트워크 정보 확인

```bash
# Docker 네트워크 정보 확인
docker network inspect docker_bitcoin-network

# 컨테이너 IP 확인
docker inspect bitcoin-node | grep -A 10 NetworkSettings
```

출력 예시:
```json
{
  "Gateway": "172.21.0.1",
  "IPAddress": "172.21.0.2",
  "IPPrefixLen": 16
}
```

### 2. RPC 연결 테스트

```bash
# 컨테이너 내부에서 테스트
docker exec bitcoin-node bitcoin-cli -rpcuser=bitcoin -rpcpassword=firpeng getblockchaininfo

# 호스트에서 직접 테스트 (실패할 수 있음)
curl -v -X POST -H "Content-Type: application/json" \
  --user "bitcoin:firpeng" \
  --data '{"jsonrpc":"2.0","method":"getblockchaininfo","params":[],"id":1}' \
  http://127.0.0.1:8332
```

### 3. 포트 연결 확인

```bash
# 포트가 열려있는지 확인
netstat -tlnp | grep 8332

# 또는
ss -tlnp | grep 8332

# telnet으로 연결 테스트
telnet 127.0.0.1 8332
```

### 4. 로그 확인

```bash
# bitcoind 로그에서 RPC 접근 시도 확인
docker logs bitcoin-node | grep -i rpc

# RPC 인증 실패 메시지 확인
docker logs bitcoin-node | grep "incorrect password"
```

## 📋 단계별 해결 체크리스트

### 1단계: Docker 네트워크 정보 확인
```bash
docker network inspect docker_bitcoin-network | grep -A 5 Gateway
```

### 2단계: docker-compose.yml 수정
```yaml
command:
  - -rpcallowip=127.0.0.1
  - -rpcallowip=172.21.0.0/16  # 확인한 네트워크 범위 추가
```

### 3단계: 컨테이너 재시작
```bash
docker-compose down
docker-compose up -d
```

### 4단계: 연결 테스트
```bash
curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:firpeng" \
  --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result'
```

## 🎯 빠른 해결 방법

### 자동으로 Docker 네트워크 IP 범위 추가

```bash
# 1. Docker 네트워크 정보 확인
NETWORK=$(docker network inspect docker_bitcoin-network --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')

# 2. docker-compose.yml 수정
# rpcallowip에 $NETWORK 추가
```

또는 수동으로:

```yaml
# docker-compose.yml
command:
  - bitcoind
  - -printtoconsole
  - -txindex=1
  - -dbcache=4500
  - -server=1
  - -rpcuser=${BITCOIN_RPC_USER:-bitcoin}
  - -rpcpassword=${BITCOIN_RPC_PASSWORD:-changeme}
  - -rpcbind=0.0.0.0
  - -rpcallowip=127.0.0.1 
  - -rpcallowip=172.21.0.0/16  # Docker 네트워크 (docker_bitcoin-network)
```

## 🔒 보안 고려사항

### 권장 설정 (프로덕션)

```yaml
command:
  - -rpcbind=127.0.0.1        # 컨테이너 내부 localhost만 바인딩
  - -rpcallowip=127.0.0.1     # 컨테이너 내부만 허용
  - -rpcallowip=172.21.0.0/16 # Docker 네트워크만 허용
```

**설명**:
- `rpcbind=127.0.0.1`: 컨테이너 내부에서만 RPC 서버 바인딩
- Docker 포트 매핑(`127.0.0.1:8332->8332/tcp`)을 통해 호스트에서 접근 가능
- `rpcallowip`로 Docker 네트워크만 허용하여 보안 유지

### 비권장 설정 (보안 위험)

```yaml
command:
  - -rpcbind=0.0.0.0
  - -rpcallowip=0.0.0.0/0     # 모든 IP 허용 (위험!)
```

**문제점**:
- 인터넷에서도 접근 가능
- 강력한 비밀번호 필수
- 방화벽 설정 필요

## 📝 추가 정보

### Docker 네트워크 타입별 동작

#### Bridge 네트워크 (현재 사용 중)
- 컨테이너는 격리된 네트워크에 있음
- 호스트에서 접근 시 Docker 네트워크를 통해 전달
- `rpcallowip`에 Docker 네트워크 IP 범위 필요

#### Host 네트워크
```yaml
network_mode: "host"
```
- 컨테이너가 호스트 네트워크를 직접 사용
- `rpcallowip=127.0.0.1`만으로도 호스트 접근 가능
- 하지만 네트워크 격리 장점 상실

### RPC 접근 방법 비교

| 방법 | 컨테이너 내부 | 호스트 | 보안 |
|------|--------------|--------|------|
| `docker exec` | ✅ | ✅ | 높음 |
| `curl` (컨테이너 내부) | ✅ | ❌ | 높음 |
| `curl` (호스트) | ❌ | ✅* | 중간* |
| 포트 포워딩 + `rpcallowip` | ✅ | ✅* | 중간* |

*`rpcallowip` 설정에 따라 다름

## 결론

**문제 원인**: `rpcallowip=127.0.0.1`은 컨테이너 내부의 localhost만 허용하며, 호스트에서 접근할 때는 Docker 네트워크를 통해 전달되므로 다른 IP로 인식됩니다.

**해결 방법**: `rpcallowip`에 Docker 네트워크 IP 범위를 추가하세요.

**권장 설정**:
```yaml
- -rpcallowip=127.0.0.1
- -rpcallowip=172.21.0.0/16  # Docker 네트워크 범위
```

이렇게 설정하면 컨테이너 내부와 호스트 모두에서 RPC 접근이 가능합니다.
