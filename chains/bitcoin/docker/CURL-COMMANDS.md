# Bitcoin 노드 curl 명령어 가이드

Docker로 실행 중인 Bitcoin 노드에 curl을 사용하여 RPC API를 호출하는 방법입니다.

## 기본 설정

현재 Docker 설정:
- **RPC 포트**: 8332 (localhost만 노출)
- **RPC 사용자**: bitcoin (기본값, 환경 변수 `BITCOIN_RPC_USER`로 변경 가능)
- **RPC 비밀번호**: changeme (기본값, 환경 변수 `BITCOIN_RPC_PASSWORD`로 변경 가능)
- **RPC URL**: `http://127.0.0.1:8332`

## 기본 curl 형식

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"METHOD_NAME","params":[],"id":1}' \
  http://127.0.0.1:8332
```

## 환경 변수 설정 (선택사항)

명령어를 간단하게 하기 위해 환경 변수를 설정할 수 있습니다:

```bash
# 환경 변수 설정
export BTC_RPC_USER="bitcoin"
export BTC_RPC_PASS="changeme"
export BTC_RPC_URL="http://127.0.0.1:8332"

# 사용 예시
curl -X POST \
  -H "Content-Type: application/json" \
  --user "${BTC_RPC_USER}:${BTC_RPC_PASS}" \
  --data '{"jsonrpc":"2.0","method":"getblockchaininfo","params":[],"id":1}' \
  ${BTC_RPC_URL}
```

## 주요 RPC 메서드 및 curl 명령어

### 1. 블록체인 정보

#### getblockchaininfo
블록체인 정보 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin" \
  --data '{"jsonrpc":"2.0","method":"getblockchaininfo","params":[],"id":1}' \
  http://127.0.0.1:8332
```

#### getblockcount
최신 블록 높이 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' \
  http://127.0.0.1:8332
```

#### getblockhash [height]
특정 높이의 블록 해시 조회

```bash
# 예: 높이 800000의 블록 해시
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockhash","params":[800000],"id":1}' \
  http://127.0.0.1:8332
```

#### getblock [blockhash]
블록 정보 조회

```bash
# 블록 해시로 조회 (verbose=1: 상세 정보, verbose=0: hex 데이터)
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblock","params":["000000000000000000019ef89e2e8e0c5e3b3e3e3e3e3e3e3e3e3e3e3e3e3e3",1],"id":1}' \
  http://127.0.0.1:8332

# 또는 "latest"로 최신 블록 조회
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblock","params":["latest",1],"id":1}' \
  http://127.0.0.1:8332
```

### 2. 네트워크 정보

#### getnetworkinfo
네트워크 정보 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getnetworkinfo","params":[],"id":1}' \
  http://127.0.0.1:8332
```

#### getconnectioncount
연결된 피어 수 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getconnectioncount","params":[],"id":1}' \
  http://127.0.0.1:8332
```

#### getpeerinfo
피어 연결 상세 정보 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getpeerinfo","params":[],"id":1}' \
  http://127.0.0.1:8332
```

### 3. 노드 상태

#### getblockchaininfo
블록체인 동기화 상태 포함

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockchaininfo","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result.verificationprogress'
```

#### getmempoolinfo
메모리 풀 정보 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getmempoolinfo","params":[],"id":1}' \
  http://127.0.0.1:8332
```

### 4. 트랜잭션 조회

#### getrawtransaction [txid] [verbose]
트랜잭션 정보 조회 (txindex=1 필요)

```bash
# verbose=0: hex 데이터 반환
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getrawtransaction","params":["txid_here",0],"id":1}' \
  http://127.0.0.1:8332

# verbose=1: JSON 형식으로 상세 정보 반환
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getrawtransaction","params":["txid_here",1],"id":1}' \
  http://127.0.0.1:8332
```

#### gettxout [txid] [n] [include_mempool]
UTXO 정보 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"gettxout","params":["txid_here",0,true],"id":1}' \
  http://127.0.0.1:8332
```

### 5. 지갑 관련 (지갑이 활성화된 경우)

#### getwalletinfo
지갑 정보 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getwalletinfo","params":[],"id":1}' \
  http://127.0.0.1:8332
```

#### listunspent [minconf] [maxconf] [addresses]
미사용 UTXO 목록 조회

```bash
# 모든 미사용 UTXO
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"listunspent","params":[],"id":1}' \
  http://127.0.0.1:8332

# 최소 1개 확인 이상의 UTXO만
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"listunspent","params":[1],"id":1}' \
  http://127.0.0.1:8332
```

### 6. 블록 탐색

#### getblockheader [hash] [verbose]
블록 헤더 정보 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockheader","params":["blockhash_here",true],"id":1}' \
  http://127.0.0.1:8332
```

#### getchaintips
모든 알려진 체인 팁 조회

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getchaintips","params":[],"id":1}' \
  http://127.0.0.1:8332
```

### 7. 노드 제어

#### stop
노드 중지

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"stop","params":[],"id":1}' \
  http://127.0.0.1:8332
```

## 응답 형식

성공적인 응답:
```json
{
  "result": { ... },
  "error": null,
  "id": 1
}
```

에러 응답:
```json
{
  "result": null,
  "error": {
    "code": -1,
    "message": "Error message here"
  },
  "id": 1
}
```

## jq를 사용한 응답 파싱

jq를 설치하면 JSON 응답을 더 쉽게 파싱할 수 있습니다:

```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

### 사용 예시

```bash
# 블록 높이만 추출
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result'

# 동기화 진행률만 추출
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockchaininfo","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result.verificationprogress'

# 피어 수만 추출
curl -X POST \
  -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getconnectioncount","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result'
```

## 편리한 스크립트 예제

### 간단한 래퍼 스크립트

`btc-rpc.sh` 파일 생성:

```bash
#!/bin/bash

RPC_USER="${BTC_RPC_USER:-bitcoin}"
RPC_PASS="${BTC_RPC_PASS:-changeme}"
RPC_URL="${BTC_RPC_URL:-http://127.0.0.1:8332}"

METHOD="$1"
shift
PARAMS="$@"

if [ -z "$PARAMS" ]; then
  PARAMS="[]"
else
  PARAMS="[$PARAMS]"
fi

curl -s -X POST \
  -H "Content-Type: application/json" \
  --user "${RPC_USER}:${RPC_PASS}" \
  --data "{\"jsonrpc\":\"2.0\",\"method\":\"${METHOD}\",\"params\":${PARAMS},\"id\":1}" \
  ${RPC_URL} | jq '.'
```

사용 예시:
```bash
chmod +x btc-rpc.sh

# 블록 높이 조회
./btc-rpc.sh getblockcount

# 블록 해시 조회
./btc-rpc.sh getblockhash 800000

# 피어 정보 조회
./btc-rpc.sh getpeerinfo
```

## 자주 사용하는 명령어 모음

### 노드 상태 확인

```bash
# 블록 높이
curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result'

# 동기화 상태
curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockchaininfo","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result | {blocks, headers, verificationprogress}'

# 피어 수
curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getconnectioncount","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result'

# 메모리 풀 크기
curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getmempoolinfo","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result.size'
```

### 블록 정보 조회

```bash
# 최신 블록 높이
curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' \
  http://127.0.0.1:8332 | jq '.result'

# 특정 높이의 블록 해시
curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockhash","params":[800000],"id":1}' \
  http://127.0.0.1:8332 | jq -r '.result'

# 블록 정보 (해시 사용)
BLOCK_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data '{"jsonrpc":"2.0","method":"getblockhash","params":[800000],"id":1}' \
  http://127.0.0.1:8332 | jq -r '.result')

curl -s -X POST -H "Content-Type: application/json" \
  --user "bitcoin:changeme" \
  --data "{\"jsonrpc\":\"2.0\",\"method\":\"getblock\",\"params\":[\"${BLOCK_HASH}\",1],\"id\":1}" \
  http://127.0.0.1:8332 | jq '.result | {hash, height, time, tx}'
```

## 보안 주의사항

1. **RPC 비밀번호 변경**: 기본 비밀번호(`changeme`)를 반드시 변경하세요
2. **localhost만 노출**: 현재 설정은 localhost(127.0.0.1)로만 RPC가 노출되어 있습니다
3. **HTTPS 사용 권장**: 프로덕션 환경에서는 HTTPS를 사용하는 것을 권장합니다
4. **방화벽 설정**: RPC 포트를 외부에 노출하지 마세요

## 문제 해결

### 연결 실패

```bash
# 컨테이너가 실행 중인지 확인
docker ps | grep bitcoin

# RPC 포트가 열려있는지 확인
netstat -tlnp | grep 8332

# 컨테이너 로그 확인
docker logs bitcoin-node
```

### 인증 실패

```bash
# RPC 사용자/비밀번호 확인
docker-compose exec bitcoind cat /home/bitcoin/.bitcoin/bitcoin.conf | grep rpc
```

## 추가 리소스

- [Bitcoin Core RPC API 문서](https://developer.bitcoin.org/reference/rpc/)
- [JSON-RPC 2.0 스펙](https://www.jsonrpc.org/specification)
