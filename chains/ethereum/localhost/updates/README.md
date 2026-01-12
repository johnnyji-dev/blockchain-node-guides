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

# 3. 최신 버전 확인 및 다운로드
# 최신 버전: https://github.com/ethereum/go-ethereum/releases 에서 확인
GETH_VERSION="1.16.7"  # 최신 버전으로 변경
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-${GETH_VERSION}.tar.gz

# 4. 압축 해제 및 설치
tar -xzf geth-linux-amd64-${GETH_VERSION}.tar.gz
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

#### Geth v1.16.7 (Ballistic Drift Stabilizer)
- **날짜**: 2024년 11월 4일
- **주요 변경사항**:
  - Fusaka 하드포크 활성화 (메인넷: 2025-12-03)
  - KZG 암호화 라이브러리 취약점 수정
  - `eth_sendRawTransactionSync` RPC 메서드 추가
  - `eth_simulateV1` 지원 개선
- **호환성**: 이전 버전과 호환
- **주의사항**: Fusaka 포크 전에 업그레이드 필요
- **릴리스 페이지**: [https://github.com/ethereum/go-ethereum/releases/tag/v1.16.7](https://github.com/ethereum/go-ethereum/releases/tag/v1.16.7)

#### Geth v1.16.6 (Leather Wrapping)
- **날짜**: 2024년 11월 3일
- **주의**: v1.16.7로 업그레이드 권장 (보안 수정 포함)
- **주요 변경사항**:
  - Fusaka 하드포크 활성화
  - BPO1, BPO2 포크 스케줄 추가
- **릴리스 페이지**: [https://github.com/ethereum/go-ethereum/releases/tag/v1.16.6](https://github.com/ethereum/go-ethereum/releases/tag/v1.16.6)

#### Geth v1.16.0 (Terran Rivets)
- **날짜**: 2024년 6월 26일
- **주요 변경사항**:
  - Path-based archive node 구현
  - 상태 데이터베이스 개선
  - 기본 블록 가스 한도 45M으로 증가
- **릴리스 페이지**: [https://github.com/ethereum/go-ethereum/releases/tag/v1.16.0](https://github.com/ethereum/go-ethereum/releases/tag/v1.16.0)

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

## Consensus Layer (Prysm) 업데이트

Prysm을 사용하는 경우 별도로 업데이트해야 합니다:

```bash
# 최신 버전 확인
# https://github.com/prysmaticlabs/prysm/releases

# Beacon Chain 업데이트
PRYSM_VERSION="v7.1.2"  # 최신 버전으로 변경
wget https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}/beacon-chain-${PRYSM_VERSION}-linux-amd64
chmod +x beacon-chain-${PRYSM_VERSION}-linux-amd64

# Validator Client 업데이트 (검증자 운영 시)
wget https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}/validator-${PRYSM_VERSION}-linux-amd64
chmod +x validator-${PRYSM_VERSION}-linux-amd64
```

## 추가 리소스

### Execution Layer (Geth)
- [Geth 릴리스 페이지](https://github.com/ethereum/go-ethereum/releases)
- [Geth 공식 문서](https://geth.ethereum.org/docs)
- [Geth 다운로드 페이지](https://geth.ethereum.org/downloads)

### Consensus Layer (Prysm)
- [Prysm 릴리스 페이지](https://github.com/prysmaticlabs/prysm/releases)
- [Prysm 공식 문서](https://docs.prylabs.network/)
