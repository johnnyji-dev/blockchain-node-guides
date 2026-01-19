# Bitcoin RPC (curl) 통합 가이드

Docker로 실행 중인 Bitcoin Core 노드의 **RPC 설정/보안/외부접속**과 **curl 호출 예시**를 하나로 통합한 문서입니다.

## 0) 현재 구성 빠른 요약 (docker-compose.yml 기준)

- **RPC 포트**: 8332
- **P2P 포트**: 8333
- **권장 보안 기본값**: RPC는 `127.0.0.1`로만 노출 + `rpcallowip=127.0.0.1`
- **외부 RPC가 필요할 때**: `ports: "8332:8332"`로 노출하되, 반드시
  - `rpcallowip`를 **특정 IP/CIDR로 제한**
  - UFW/보안그룹에서 **해당 IP만 8332 허용**

## 1) 가장 간단한 호출 템플릿

### A. 로컬(서버 내부)에서 호출

```bash
RPC_URL="http://127.0.0.1:8332"
RPC_USER="bitcoin"
RPC_PASS="<RPC_PASSWORD>"

curl -sS -X POST \
  -H "Content-Type: application/json" \
  --user "${RPC_USER}:${RPC_PASS}" \
  --data '{"jsonrpc":"2.0","method":"getblockchaininfo","params":[],"id":1}' \
  "${RPC_URL}"
```

### B. 편의 함수(권장)

```bash
btc_rpc () {
  local method="$1"; shift
  local params="${1:-[]}"
  curl -sS -X POST \
    -H "Content-Type: application/json" \
    --user "${RPC_USER}:${RPC_PASS}" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"${method}\",\"params\":${params},\"id\":1}" \
    "${RPC_URL}"
}

# 예시
btc_rpc getblockcount
btc_rpc getblockhash "[800000]"
```

## 2) 자주 쓰는 RPC 메서드 목록 (curl 예시 포함)

### 노드/동기화 상태

```bash
btc_rpc getblockchaininfo
btc_rpc getnetworkinfo
btc_rpc getconnectioncount
btc_rpc getmempoolinfo
```

### 블록 조회

```bash
# 최신 높이
btc_rpc getblockcount

# 특정 높이의 블록 해시
btc_rpc getblockhash "[800000]"

# 블록 상세(verbosity=1)
BLOCK_HASH=$(btc_rpc getblockhash "[800000]" | jq -r '.result')
btc_rpc getblock "[\"${BLOCK_HASH}\", 1]"
```

### 트랜잭션 조회 / 브로드캐스팅

> `getrawtransaction`은 보통 `txindex=1`이 필요합니다(이미 켜두는 구성이 많음).

```bash
# 트랜잭션 조회(verbosity=1)
btc_rpc getrawtransaction "[\"<TXID>\", 1]"

# 전파 전 검증
btc_rpc testmempoolaccept "[[\"<RAW_TX_HEX>\"]]"

# 전파
btc_rpc sendrawtransaction "[\"<RAW_TX_HEX>\"]"
```

## 3) 외부에서 RPC 접근 허용(권장 방식)

### 3-1) docker-compose 포트 노출

외부에서 접근해야 하면 아래처럼 **호스트 8332를 외부에 노출**합니다.

```yaml
ports:
  - "8333:8333"
  - "8332:8332"   # 외부 접근이 필요할 때만
```

### 3-2) rpcallowip를 “접근할 IP만” 허용

```yaml
command:
  - -rpcbind=0.0.0.0
  - -rpcallowip=127.0.0.1
  - -rpcallowip=172.21.0.0/16     # Docker 네트워크(호스트→컨테이너 포워딩 소스가 이 대역일 수 있음)
  - -rpcallowip=<YOUR_CLIENT_IP>  # 예: 203.0.113.10
  # 또는 사설망 대역
  # - -rpcallowip=192.168.0.0/24
```

> 절대 권장하지 않음: `-rpcallowip=0.0.0.0/0` (인터넷 전체에 RPC 오픈)

### 3-3) 방화벽(UFW)도 반드시 제한

```bash
# 예: 특정 클라이언트 IP만 8332 허용
sudo ufw allow from <YOUR_CLIENT_IP> to any port 8332 proto tcp

# P2P는 일반적으로 전체 허용(환경에 따라)
sudo ufw allow 8333/tcp
sudo ufw allow 8333/udp

sudo ufw status
```

### 3-4) 외부에서 호출 예시

```bash
RPC_URL="http://<SERVER_PUBLIC_IP>:8332"
RPC_USER="bitcoin"
RPC_PASS="<RPC_PASSWORD>"

btc_rpc getblockchaininfo | jq '.result | {chain, blocks, headers, verificationprogress}'
```

## 4) “호스트에서는 안 되고 컨테이너에서는 되는” 경우(핵심)

원인 요약:
- 호스트에서 `http://127.0.0.1:8332`로 호출하더라도, bitcoind가 보는 소스 IP가 Docker 게이트웨이(예: `172.21.0.1`)로 잡힐 수 있습니다.
- 이때 `rpcallowip=127.0.0.1`만 있으면 **호스트 호출이 거부**됩니다.

해결:
- `rpcallowip`에 **Docker 네트워크 CIDR**(예: `172.21.0.0/16`)를 추가

## 5) 문제 해결(증상별)

### 5-1) Connection refused

체크 순서:
1) 포트가 실제로 열려있는지
2) docker-compose 포트 매핑이 올바른지
3) 방화벽이 막는지

```bash
sudo ss -tlnp | grep 8332
docker ps --format 'table {{.Names}}\t{{.Ports}}' | grep bitcoin
sudo ufw status
```

추가로 유용한 확인:

```bash
# (외부 클라이언트에서) 포트 레벨 연결 확인
nc -zv <SERVER_PUBLIC_IP> 8332

# (외부 클라이언트 IP 확인)
curl ifconfig.me
```

### 5-2) Authorization failed / incorrect password attempt

체크 순서:
1) `bitcoin.conf`의 `rpcuser/rpcpassword` vs `docker-compose.yml`의 `BITCOIN_RPC_USER/PASSWORD`가 충돌하는지
2) 쿠키(.cookie) 기반 접근이 가능한지(헬스체크/컨테이너 내부)

```bash
docker logs bitcoin-node | grep -i 'incorrect password\|Authorization failed' | tail -n 20
```

### 5-3) `unhealthy`인데 노드는 정상처럼 보일 때(헬스체크/인증 이슈)

자주 보는 로그:
- `ThreadRPCServer incorrect password attempt from ...`

실효적인 체크 순서:

```bash
# 헬스체크 상태/최근 실패 원인
docker inspect --format='{{json .State.Health}}' bitcoin-node | jq

# 쿠키 파일 존재(컨테이너 내부)
docker exec bitcoin-node ls -la /home/bitcoin/.bitcoin/.cookie || true
```

권장:
- 헬스체크는 **쿠키(.cookie) 우선**이 가장 안정적입니다.
- `bitcoin.conf`와 `docker-compose.yml`에서 RPC 인증을 두 군데에서 동시에 관리하면 충돌이 잦으니, 한 곳으로 정리하세요.

## 6) 참고

- Bitcoin Core RPC 레퍼런스: `https://developer.bitcoin.org/reference/rpc/`

