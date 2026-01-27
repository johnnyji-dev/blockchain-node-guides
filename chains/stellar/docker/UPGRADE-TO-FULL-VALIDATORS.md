# Full Validator 설정으로 업그레이드하기

현재는 **옵션 1** (단순 설정 - SDF 3개 validator)을 사용 중입니다.

나중에 더 많은 validator를 사용하는 **옵션 2**로 전환하려면 아래 가이드를 따르세요.

## 옵션 비교

### 옵션 1: 현재 사용 중 ✅
- **파일**: `stellar-core-official.cfg`
- **Validator**: SDF 3개
- **장점**: 단순, 안정적, 리소스 효율적
- **권장**: 초기 설정, 테스트, 리소스 제한 환경

### 옵션 2: 전체 Validator 설정
- **파일**: `stellar-core-official-full.cfg.backup`
- **Validator**: 27개 (7개 조직)
  - SDF (3)
  - PublicNode (3)
  - LOBSTR (5)
  - Franklin Templeton (3)
  - SatoshiPay (3)
  - Creit (3)
  - Blockdaemon (3)
- **장점**: 높은 탈중앙화, 더 안정적
- **권장**: 프로덕션 환경, 충분한 리소스

## 업그레이드 시점

다음 조건이 충족되면 업그레이드를 고려하세요:

1. ✅ 노드가 완전히 동기화됨
2. ✅ 최소 3-7일간 안정적으로 작동
3. ✅ 서버 리소스가 충분함 (RAM 10GB+, 네트워크 20Mbps+)
4. ✅ 더 높은 탈중앙화가 필요함

## 업그레이드 방법

### 1단계: 백업 확인
```bash
cd ~/blockchain-node-guides/chains/stellar/docker

# 백업 파일이 있는지 확인
ls -lh stellar-core-official-full.cfg.backup
```

### 2단계: 컨테이너 중지
```bash
docker compose -f docker-compose-official.yml down
```

### 3단계: 설정 파일 교체
```bash
# 현재 설정 백업
cp stellar-core-official.cfg stellar-core-official-simple.cfg.backup

# 전체 설정으로 교체
cp stellar-core-official-full.cfg.backup stellar-core-official.cfg
```

### 4단계: 재시작
```bash
docker compose -f docker-compose-official.yml up -d
```

### 5단계: 로그 확인
```bash
# stellar-core 로그
docker logs stellar-core -f

# 다음 메시지가 나오는지 확인:
# - "Listening on 11625 for peers"
# - "Syncing ledger..."
```

## 롤백 방법 (문제 발생 시)

```bash
# 컨테이너 중지
docker compose -f docker-compose-official.yml down

# 단순 설정으로 복원
cp stellar-core-official-simple.cfg.backup stellar-core-official.cfg

# 재시작
docker compose -f docker-compose-official.yml up -d
```

## 리소스 요구사항

| 항목 | 옵션 1 (현재) | 옵션 2 (전체) |
|------|---------------|---------------|
| RAM | 8GB | 10-12GB |
| 네트워크 | 10Mbps | 20-30Mbps |
| 동기화 시간 | 2-5일 | 3-7일 |
| CPU | 4 cores | 4-8 cores |

## 주의사항

1. **동기화 중 전환 금지**: 노드가 완전히 동기화된 후에만 전환하세요.
2. **리소스 모니터링**: 전환 후 CPU, RAM, 네트워크 사용량을 모니터링하세요.
3. **데이터 보존**: 전환 시 기존 ledger 데이터는 유지됩니다.

## 확인 명령어

```bash
# 현재 사용 중인 validator 확인
docker exec stellar-core stellar-core http-command 'info' | grep -A 20 'quorum'

# 연결된 피어 수 확인
docker exec stellar-core stellar-core http-command 'peers'
```

## 도움말

문제가 발생하면:
1. 로그 확인: `docker logs stellar-core --tail 100`
2. 단순 설정으로 롤백
3. 리소스 확인: `free -h`, `df -h`
