# Bitcoin 노드 트러블슈팅 가이드

Bitcoin 노드 운영 중 발생하는 일반적인 문제와 해결 방법입니다.

## 목차
- [일반적인 오류](#일반적인-오류)
- [동기화 문제](#동기화-문제)
- [성능 이슈](#성능-이슈)
- [네트워크 문제](#네트워크-문제)
- [데이터 손상](#데이터-손상)
- [RPC 문제](#rpc-문제)

## 일반적인 오류

### "Error: Cannot obtain a lock on data directory"
**증상**: 노드가 시작되지 않고 위 오류 메시지가 표시됨

**원인**: 다른 Bitcoin Core 프로세스가 이미 실행 중이거나 이전 프로세스가 비정상 종료됨

**해결 방법**:
```bash
# 실행 중인 프로세스 확인
ps aux | grep bitcoind

# 프로세스 종료
killall bitcoind

# 또는 lock 파일 삭제 (주의: 데이터 손상 위험)
rm ~/.bitcoin/.lock
```

### "Error: Initializing networking failed"
**증상**: 네트워크 초기화 실패

**원인**: 포트가 이미 사용 중이거나 방화벽 설정 문제

**해결 방법**:
```bash
# 포트 사용 확인
netstat -tlnp | grep 8333

# 방화벽 확인
sudo ufw status
sudo ufw allow 8333/tcp
```

## 동기화 문제

### 동기화가 매우 느림
**증상**: 블록 동기화 속도가 매우 느림

**해결 방법**:
1. **더 많은 피어 연결**:
   ```conf
   maxconnections=125
   ```

2. **SSD 사용**: HDD 대신 SSD 사용 권장

3. **데이터베이스 캐시 증가**:
   ```conf
   dbcache=4500
   ```

4. **스냅샷 사용**: 초기 동기화 시 스냅샷 다운로드

### 동기화 실패
**증상**: 동기화가 중단되거나 실패함

**해결 방법**:
```bash
# 블록체인 정보 확인
bitcoin-cli getblockchaininfo

# 재인덱싱 (시간이 오래 걸릴 수 있음)
bitcoind -reindex

# 또는 체인 상태 재구성
bitcoind -reindex-chainstate
```

### 포크 발생
**증상**: 로컬 체인이 메인 체인과 다른 포크에 있음

**해결 방법**:
```bash
# 블록체인 정보 확인
bitcoin-cli getblockchaininfo

# 자동으로 올바른 체인으로 전환 (일반적으로 자동 처리됨)
# 필요시 재인덱싱
bitcoind -reindex
```

## 성능 이슈

### 높은 CPU 사용률
**원인**: 블록 검증, 트랜잭션 처리, 인덱싱

**해결 방법**:
1. **데이터베이스 캐시 조정**:
   ```conf
   dbcache=4500
   ```

2. **트랜잭션 인덱스 비활성화** (필요하지 않은 경우):
   ```conf
   # txindex=0
   ```

### 높은 메모리 사용률
**원인**: 데이터베이스 캐시, 메모리 풀

**해결 방법**:
```conf
# 데이터베이스 캐시 크기 조정
dbcache=2000

# 메모리 풀 크기 제한
maxmempool=300
```

### 디스크 I/O 병목
**원인**: 블록체인 데이터 읽기/쓰기

**해결 방법**:
1. **SSD 사용**: HDD 대신 SSD 사용
2. **데이터베이스 캐시 증가**: 더 많은 RAM 할당
3. **디스크 여유 공간 확인**: 최소 20% 이상 여유 공간 유지

## 네트워크 문제

### 피어 연결 실패
**증상**: 다른 노드와 연결되지 않음

**해결 방법**:
```bash
# 네트워크 정보 확인
bitcoin-cli getnetworkinfo

# 연결 수 확인
bitcoin-cli getconnectioncount

# 수동으로 피어 추가
bitcoin-cli addnode "node_ip:8333" "add"
```

### 포트 문제
**증상**: 외부에서 노드에 접근할 수 없음

**해결 방법**:
```bash
# 포트 리스닝 확인
netstat -tlnp | grep 8333

# 방화벽 설정
sudo ufw allow 8333/tcp
sudo ufw allow 8333/udp

# 라우터 포트 포워딩 설정 (필요한 경우)
```

## 데이터 손상

### 체크섬 오류
**증상**: 데이터베이스 체크섬 오류

**해결 방법**:
```bash
# 재인덱싱
bitcoind -reindex

# 또는 체인 상태만 재구성
bitcoind -reindex-chainstate
```

### 데이터베이스 복구
**증상**: 데이터베이스가 손상됨

**해결 방법**:
```bash
# 자동 복구 시도
bitcoind -salvagewallet

# 또는 백업에서 복원
# 1. bitcoind 중지
# 2. 백업 디렉토리에서 파일 복원
# 3. bitcoind 재시작
```

## RPC 문제

### RPC 연결 실패
**증상**: `bitcoin-cli` 명령이 작동하지 않음

**해결 방법**:
1. **RPC 서버 활성화 확인**:
   ```conf
   server=1
   ```

2. **RPC 인증 정보 확인**:
   ```conf
   rpcuser=your_username
   rpcpassword=your_password
   ```

3. **RPC 포트 확인**:
   ```bash
   bitcoin-cli -rpcport=8332 getinfo
   ```

### RPC 권한 오류
**증상**: RPC 명령 실행 시 권한 오류

**해결 방법**:
```conf
# RPC 허용 IP 확인
rpcallowip=127.0.0.1

# 또는 특정 네트워크 허용
# rpcallowip=192.168.1.0/24
```

## 로그 확인

### 로그 파일 위치
- **Linux**: `~/.bitcoin/debug.log`
- **macOS**: `~/Library/Application Support/Bitcoin/debug.log`
- **Windows**: `%APPDATA%\Bitcoin\debug.log`

### 유용한 로그 명령어
```bash
# 실시간 로그 확인
tail -f ~/.bitcoin/debug.log

# 에러만 확인
grep -i error ~/.bitcoin/debug.log

# 최근 100줄 확인
tail -n 100 ~/.bitcoin/debug.log
```

## 추가 도움말

- [Bitcoin Core 공식 문서](https://bitcoin.org/en/developer-documentation)
- [Bitcoin Stack Exchange](https://bitcoin.stackexchange.com/)
- [GitHub Issues](https://github.com/bitcoin/bitcoin/issues)

