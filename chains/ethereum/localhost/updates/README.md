# Ethereum 노드 업데이트 로그

Geth 노드 업데이트 및 변경 사항을 기록합니다.

## 업데이트 가이드

### 업데이트 전 준비사항

1. **데이터 백업**: 업데이트 전에 데이터 디렉토리를 백업하세요
2. **노드 중지**: 업데이트 전에 노드를 안전하게 중지하세요
3. **릴리스 노트 확인**: 업데이트 내용과 호환성을 확인하세요

### 업데이트 방법

#### 바이너리 다운로드 방식

```bash
# 1. 현재 노드 중지
killall geth

# 2. 백업
tar -czf ethereum-backup-$(date +%Y%m%d).tar.gz ~/.ethereum

# 3. 새 버전 다운로드
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-[버전].tar.gz

# 4. 압축 해제 및 설치
tar -xzf geth-linux-amd64-[버전].tar.gz
sudo install -m 0755 -o root -g root geth /usr/local/bin/

# 5. 버전 확인
geth version

# 6. 노드 재시작
geth --mainnet --datadir ~/.ethereum --syncmode snap
```

#### 패키지 매니저 방식 (Ubuntu/Debian)

```bash
# 1. 현재 노드 중지
sudo systemctl stop geth

# 2. 백업
tar -czf ethereum-backup-$(date +%Y%m%d).tar.gz ~/.ethereum

# 3. 업데이트
sudo apt-get update
sudo apt-get upgrade ethereum

# 4. 버전 확인
geth version

# 5. 노드 재시작
sudo systemctl start geth
```

## 업데이트 기록

### 2024년

#### Geth 1.13.15
- **날짜**: 2024년
- **주요 변경사항**:
  - 성능 개선
  - 버그 수정
- **호환성**: 이전 버전과 호환
- **주의사항**: 없음

---

## 업데이트 체크리스트

업데이트 시 다음 사항을 확인하세요:

- [ ] 데이터 백업 완료
- [ ] 노드 안전하게 중지
- [ ] 릴리스 노트 확인
- [ ] 새 버전 다운로드 및 설치
- [ ] 버전 확인
- [ ] 노드 재시작
- [ ] 동기화 상태 확인
- [ ] RPC 연결 테스트

## 롤백 방법

문제가 발생하면 이전 버전으로 롤백할 수 있습니다:

```bash
# 1. 노드 중지
killall geth

# 2. 이전 버전 다운로드 및 설치
# (위의 업데이트 방법 참고)

# 3. 노드 재시작
geth --mainnet --datadir ~/.ethereum --syncmode snap
```

## 추가 리소스

- [Geth 릴리스 페이지](https://github.com/ethereum/go-ethereum/releases)
- [Geth 공식 문서](https://geth.ethereum.org/docs)
