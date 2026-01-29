# Stellar 노드 curl 명령어 모음

Stellar 노드의 정보를 조회하는 curl 명령어 모음입니다.

## 목차

- [최신 블록/원장 조회](#최신-블록원장-조회)
- [동기화 상태 확인](#동기화-상태-확인)
- [노드 정보 조회](#노드-정보-조회)
- [피어 연결 상태](#피어-연결-상태)
- [계정 정보 조회](#계정-정보-조회)
- [트랜잭션 조회](#트랜잭션-조회)
- [빠른 상태 확인 스크립트](#빠른-상태-확인-스크립트)

---

## 최신 블록/원장 조회

### Horizon API

```bash
# 최신 원장 조회 (가장 최근 원장)
curl http://localhost:8100/ledgers?limit=1&order=desc

# 최신 원장 상세 정보 (JSON 형식, jq 사용)
curl http://localhost:8100/ledgers?limit=1&order=desc | jq

# 최신 원장 번호만 추출
curl -s http://localhost:8100/ledgers?limit=1&order=desc | jq -r '.records[0].sequence'

# 최신 원장의 트랜잭션 수
curl -s http://localhost:8100/ledgers?limit=1&order=desc | jq -r '.records[0].transaction_count'

# 최신 원장의 작업(Operation) 수
curl -s http://localhost:8100/ledgers?limit=1&order=desc | jq -r '.records[0].operation_count'

# 최신 원장의 종료 시간
curl -s http://localhost:8100/ledgers?limit=1&order=desc | jq -r '.records[0].closed_at'

# 원장 목록 조회 (최근 10개)
curl http://localhost:8100/ledgers?limit=10&order=desc | jq

# 특정 원장 번호 조회
curl http://localhost:8100/ledgers/60958653 | jq

# 원장 통계 요약
curl -s http://localhost:8100/ledgers?limit=1&order=desc | jq '.records[0] | {
  sequence,
  transaction_count,
  operation_count,
  closed_at,
  total_coins,
  fee_pool
}'
```

### stellar-core HTTP API

```bash
# 현재 원장 정보
curl http://localhost:11626/info | jq '.info.ledger'
curl http://162.19.222.84:11626/info | jq '.info.ledger'

# 최신 원장 번호
curl -s http://localhost:11626/info | jq -r '.info.ledger.num'

# 원장 버전 (프로토콜 버전)
curl -s http://localhost:11626/info | jq -r '.info.ledger.version'

# 원장 해시
curl -s http://localhost:11626/info | jq -r '.info.ledger.hash'
```

### RPC API

```bash
# 최신 원장 정보
curl -X POST http://localhost:8100/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getLatestLedger"}' | jq

# 최신 원장 번호만 추출
curl -s -X POST http://localhost:8100/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getLatestLedger"}' | jq -r '.result.sequence'
```


curl -s -X POST https://horizon.stellar.org/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getLatestLedger"}' | jq -r '.result.sequence'

---

## 동기화 상태 확인

### Horizon 동기화 상태

```bash
# Horizon 전체 상태 (동기화 상태 포함)
curl http://localhost:8100/ | jq

# Core와 History 동기화 상태 비교
curl -s http://localhost:8100/ | jq '{
  core_latest_ledger,
  history_latest_ledger,
  history_elder_ledger,
  core_elder_ledger
}'

# 동기화 완료 여부 확인 (true/false)
curl -s http://localhost:8100/ | jq '.core_latest_ledger == .history_latest_ledger'

# 동기화 지연(Lag) 확인
curl -s http://localhost:8100/ | jq '{
  core_latest: .core_latest_ledger,
  history_latest: .history_latest_ledger,
  lag: (.core_latest_ledger - .history_latest_ledger),
  synced: (.core_latest_ledger == .history_latest_ledger)
}'

# 동기화 진행률 (백분율)
curl -s http://localhost:8100/ | jq '{
  core_latest: .core_latest_ledger,
  history_latest: .history_latest_ledger,
  progress: ((.history_latest_ledger / .core_latest_ledger) * 100)
}'

# 동기화 상태 요약
curl -s http://localhost:8100/ | jq '{
  status: (if .core_latest_ledger == .history_latest_ledger then "synced" else "syncing" end),
  core: .core_latest_ledger,
  history: .history_latest_ledger,
  lag: (.core_latest_ledger - .history_latest_ledger)
}'
```

### stellar-core 동기화 상태

```bash
# 노드 상태 확인
curl -s http://localhost:11626/info | jq '.info.state'

# 노드 상태 상세 정보
curl -s http://localhost:11626/info | jq '{
  state: .info.state,
  ledger: .info.ledger.num,
  protocol_version: .info.ledger.version,
  quorum: .info.quorum
}'

# 동기화 중인지 확인
curl -s http://localhost:11626/info | jq '.info.state == "Synced!"'
```

---

## 노드 정보 조회

### stellar-core 노드 정보

```bash
# 노드 전체 정보
curl http://localhost:11626/info | jq

# 노드 상태
curl -s http://localhost:11626/info | jq -r '.info.state'

# 노드 시작 시간
curl -s http://localhost:11626/info | jq -r '.info.startedOn'

# 현재 원장 정보
curl -s http://localhost:11626/info | jq '.info.ledger'

# 프로토콜 버전
curl -s http://localhost:11626/info | jq -r '.info.ledger.version'

# 네트워크 패스프레이즈
curl -s http://localhost:11626/info | jq -r '.info.networkPassphrase'

# 노드 버전
curl -s http://localhost:11626/info | jq -r '.info.build'
```

### 노드 메트릭

```bash
# 전체 메트릭
curl http://localhost:11626/metrics | jq

# 원장 통계
curl -s http://localhost:11626/metrics | jq '{
  transaction_count: .metrics."ledger.transaction.count".count,
  operation_count: .metrics."ledger.operation.count".count
}'

# 성능 메트릭
curl -s http://localhost:11626/metrics | jq '{
  ledger_close_time: .metrics."ledger.close".count,
  transaction_apply_time: .metrics."ledger.transaction.apply".count
}'
```

---

## 피어 연결 상태

### stellar-core 피어 정보

```bash
# 피어 전체 정보
curl http://localhost:11626/peers | jq

# 인바운드 피어 수
curl -s http://localhost:11626/info | jq -r '.info.peers.numTotalInboundPeers'

# 아웃바운드 피어 수
curl -s http://localhost:11626/info | jq -r '.info.peers.numTotalOutboundPeers'

# 총 피어 수
curl -s http://localhost:11626/info | jq '{
  inbound: .info.peers.numTotalInboundPeers,
  outbound: .info.peers.numTotalOutboundPeers,
  total: (.info.peers.numTotalInboundPeers + .info.peers.numTotalOutboundPeers)
}'

# 피어 상세 목록
curl -s http://localhost:11626/peers | jq '.peers[] | {
  id,
  address,
  port,
  version,
  overlay_version,
  ledger: .ledger,
  state
}'
```

---

## 계정 정보 조회

```bash
# 계정 정보 조회 (계정 ID로)
curl http://localhost:8100/accounts/GACCOUNT... | jq

# 계정 잔액
curl -s http://localhost:8100/accounts/GACCOUNT... | jq '.balances'

# 계정 시퀀스 번호
curl -s http://localhost:8100/accounts/GACCOUNT... | jq -r '.sequence'

# 계정 서브 엔트리 수
curl -s http://localhost:8100/accounts/GACCOUNT... | jq -r '.subentry_count'

# 계정의 최근 트랜잭션
curl http://localhost:8100/accounts/GACCOUNT.../transactions?limit=10 | jq

# 계정의 최근 작업(Operation)
curl http://localhost:8100/accounts/GACCOUNT.../operations?limit=10 | jq
```

---

## 트랜잭션 조회

```bash
# 최근 트랜잭션 조회
curl http://localhost:8100/transactions?limit=10&order=desc | jq

# 특정 트랜잭션 조회 (트랜잭션 해시로)
curl http://localhost:8100/transactions/TXHASH... | jq

# 트랜잭션 상세 정보
curl -s http://localhost:8100/transactions/TXHASH... | jq '{
  hash,
  ledger,
  created_at,
  source_account,
  fee_paid,
  operation_count,
  successful
}'

# 트랜잭션의 작업(Operation) 목록
curl http://localhost:8100/transactions/TXHASH.../operations | jq

# 최근 작업(Operation) 조회
curl http://localhost:8100/operations?limit=10&order=desc | jq
```

---

## 빠른 상태 확인 스크립트

다음 스크립트를 `check-status.sh`로 저장하고 실행하세요:

```bash
#!/bin/bash

echo "=========================================="
echo "Stellar 노드 상태 확인"
echo "=========================================="
echo ""

# 1. 컨테이너 상태
echo "1. 컨테이너 상태:"
docker ps | grep stellar || echo "컨테이너가 실행 중이지 않습니다"
echo ""

# 2. Horizon 동기화 상태
echo "2. Horizon 동기화 상태:"
SYNC_STATUS=$(curl -s http://localhost:8100/ | jq '{
  core_latest: .core_latest_ledger,
  history_latest: .history_latest_ledger,
  lag: (.core_latest_ledger - .history_latest_ledger),
  synced: (.core_latest_ledger == .history_latest_ledger)
}')
echo "$SYNC_STATUS" | jq
echo ""

# 3. 최신 원장 정보
echo "3. 최신 원장 정보:"
LATEST_LEDGER=$(curl -s http://localhost:8100/ledgers?limit=1&order=desc | jq '.records[0] | {
  sequence,
  transaction_count,
  operation_count,
  closed_at,
  total_coins
}')
echo "$LATEST_LEDGER" | jq
echo ""

# 4. stellar-core 노드 상태
echo "4. stellar-core 노드 상태:"
CORE_INFO=$(curl -s http://localhost:11626/info | jq '{
  state: .info.state,
  ledger: .info.ledger.num,
  protocol_version: .info.ledger.version,
  peers: {
    inbound: .info.peers.numTotalInboundPeers,
    outbound: .info.peers.numTotalOutboundPeers,
    total: (.info.peers.numTotalInboundPeers + .info.peers.numTotalOutboundPeers)
  }
}')
echo "$CORE_INFO" | jq
echo ""

# 5. RPC Health
echo "5. RPC Health:"
RPC_HEALTH=$(curl -s -X POST http://localhost:8100/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq -r '.result.status')
echo "Status: $RPC_HEALTH"
echo ""

echo "=========================================="
```

사용 방법:

```bash
# 스크립트 저장
cat > check-status.sh << 'EOF'
[위 스크립트 내용]
EOF

# 실행 권한 부여
chmod +x check-status.sh

# 실행
./check-status.sh
```

---

## 외부에서 접근하는 경우

서버 IP가 `162.19.222.84`인 경우:

```bash
# Horizon API
curl http://162.19.222.84:8100/ledgers?limit=1&order=desc

# 동기화 상태
curl http://162.19.222.84:8100/ | jq

# 최신 원장 번호
curl -s http://162.19.222.84:8100/ledgers?limit=1&order=desc | jq -r '.records[0].sequence'
```

**참고**: 
- `11626` 포트는 로컬호스트만 노출되어 있으므로 외부에서 접근할 수 없습니다
- `8100` 포트는 외부에서 접근 가능합니다 (방화벽 설정 확인 필요)

---

## 유용한 jq 명령어

```bash
# JSON을 보기 좋게 출력
curl -s http://localhost:8100/ | jq

# 특정 필드만 추출
curl -s http://localhost:8100/ | jq '.core_latest_ledger'

# 여러 필드를 객체로 추출
curl -s http://localhost:8100/ | jq '{core: .core_latest_ledger, history: .history_latest_ledger}'

# 배열의 첫 번째 요소
curl -s http://localhost:8100/ledgers?limit=1 | jq '.records[0]'

# 조건부 출력
curl -s http://localhost:8100/ | jq 'if .core_latest_ledger == .history_latest_ledger then "Synced" else "Syncing" end'
```

---

## 참고

- [Horizon API 문서](https://developers.stellar.org/api)
- [stellar-core HTTP API](https://developers.stellar.org/docs/run-core-node/admin-http-interface)
- [RPC API 문서](https://developers.stellar.org/docs/data/rpc)
