# Ethereum 노드 트러블슈팅 가이드

Ethereum 노드 운영 중 발생하는 일반적인 문제와 해결 방법입니다.

## 목차
- [일반적인 오류](#일반적인-오류)
- [동기화 문제](#동기화-문제)
- [성능 이슈](#성능-이슈)
- [네트워크 문제](#네트워크-문제)
- [데이터 손상](#데이터-손상)
- [RPC 문제](#rpc-문제)

## 일반적인 오류

### "Fatal: Failed to write genesis block"
**증상**: 노드가 시작되지 않고 위 오류 메시지가 표시됨

**원인**: 데이터 디렉토리에 쓰기 권한이 없거나 디스크 공간 부족

**해결 방법**:
```bash
# 데이터 디렉토리 권한 확인
ls -ld ~/.ethereum

# 권한 수정
chmod 755 ~/.ethereum

# 디스크 공간 확인
df -h ~/.ethereum
```

### "Fatal: Failed to start the Ethereum service"
**증상**: 서비스 시작 실패

**원인**: 포트가 이미 사용 중이거나 설정 파일 오류

**해결 방법**:
```bash
# 포트 사용 확인
netstat -tlnp | grep 30303
netstat -tlnp | grep 8545

# 실행 중인 Geth 프로세스 확인
ps aux | grep geth

# 프로세스 종료
killall geth

# 설정 파일 확인
geth --config ~/.ethereum/geth.toml --help
```

## 동기화 문제

### 동기화가 매우 느림
**증상**: 블록 동기화 속도가 매우 느림

**해결 방법**:
1. **캐시 크기 증가**:
   ```bash
   geth --mainnet --cache 8192 --syncmode snap
   ```

2. **SSD 사용**: HDD 대신 SSD 사용 권장

3. **더 많은 피어 연결**:
   ```bash
   geth --mainnet --maxpeers 100
   ```

4. **Snap sync 사용** (권장):
   ```bash
   geth --mainnet --syncmode snap
   ```

### 동기화 실패
**증상**: 동기화가 중단되거나 실패함

**해결 방법**:
```bash
# 동기화 상태 확인
geth attach --exec 'eth.syncing'

# 최신 블록 번호 확인
geth attach --exec 'eth.blockNumber'

# 재동기화 (시간이 오래 걸릴 수 있음)
geth --mainnet --datadir ~/.ethereum --syncmode snap --reinit
```

### 포크 발생
**증상**: 로컬 체인이 메인 체인과 다른 포크에 있음

**해결 방법**:
```bash
# 체인 상태 확인
geth attach --exec 'eth.syncing'

# 자동으로 올바른 체인으로 전환 (일반적으로 자동 처리됨)
# 문제가 지속되면 재동기화
geth --mainnet --datadir ~/.ethereum --syncmode snap
```

## 성능 이슈

### 높은 CPU 사용률
**증상**: CPU 사용률이 지속적으로 높음

**해결 방법**:
1. **캐시 크기 조정**: 너무 높은 캐시는 CPU 부하를 증가시킬 수 있습니다
2. **동기화 모드 확인**: snap 모드가 full 모드보다 CPU 사용량이 적습니다
3. **피어 수 제한**: 너무 많은 피어는 CPU 부하를 증가시킵니다

### 높은 메모리 사용률
**증상**: 메모리 사용량이 매우 높음

**해결 방법**:
```bash
# 캐시 크기 감소
geth --mainnet --cache 2048

# 메모리 사용량 모니터링
geth attach --exec 'admin.nodeInfo'
```

### 높은 디스크 I/O
**증상**: 디스크 I/O가 매우 높음

**해결 방법**:
1. **SSD 사용**: HDD 대신 SSD 사용
2. **캐시 크기 증가**: 더 많은 캐시는 디스크 I/O를 줄입니다
3. **동기화 모드**: snap 모드가 full 모드보다 디스크 I/O가 적습니다

## 네트워크 문제

### 피어 연결 실패
**증상**: 다른 노드와 연결할 수 없음

**해결 방법**:
```bash
# 피어 수 확인
geth attach --exec 'net.peerCount'

# 네트워크 정보 확인
geth attach --exec 'admin.peers'

# 포트 확인
netstat -tlnp | grep 30303

# 방화벽 확인
sudo ufw status
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp
```

### 인바운드 연결 없음
**증상**: 아웃바운드 연결만 있고 인바운드 연결이 없음

**해결 방법**:
1. **포트 포워딩**: 라우터에서 30303 포트 포워딩 설정
2. **방화벽 설정**: 30303 포트(TCP/UDP) 열기
3. **NAT 설정**: NAT 뒤에 있는 경우 UPnP 활성화

## 데이터 손상

### 데이터베이스 오류
**증상**: 데이터베이스 관련 오류 메시지

**해결 방법**:
```bash
# 데이터베이스 재인덱싱
geth --mainnet --datadir ~/.ethereum --reinit

# 또는 데이터 디렉토리 삭제 후 재동기화 (주의: 모든 데이터 삭제)
# 백업 후 실행
rm -rf ~/.ethereum/geth
geth --mainnet --datadir ~/.ethereum --syncmode snap
```

## RPC 문제

### RPC 연결 실패
**증상**: RPC 요청이 실패함

**해결 방법**:
```bash
# RPC 설정 확인
geth attach --exec 'admin.nodeInfo'

# RPC 포트 확인
netstat -tlnp | grep 8545

# RPC 테스트
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

### CORS 오류
**증상**: 웹 애플리케이션에서 CORS 오류 발생

**해결 방법**:
```toml
[HTTP]
CorsDomain = ["*"]  # 개발용
# 또는 특정 도메인만 허용
# CorsDomain = ["https://example.com"]
```

## 추가 리소스

- [Geth 공식 문서](https://geth.ethereum.org/docs)
- [Geth GitHub Issues](https://github.com/ethereum/go-ethereum/issues)
- [Ethereum Stack Exchange](https://ethereum.stackexchange.com/)
