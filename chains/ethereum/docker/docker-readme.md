# Ethereum 노드 Docker 가이드

Docker를 사용하여 Geth (Execution Layer)와 Prysm (Consensus Layer)를 통합 실행하는 방법입니다.

## 목차
- [빠른 시작](#빠른-시작)
- [Dockerfile 설명](#dockerfile-설명)
- [docker-compose 사용](#docker-compose-사용)
- [환경 변수 설정](#환경-변수-설정)
- [데이터 관리](#데이터-관리)
- [문제 해결](#문제-해결)

## 빠른 시작

### 1. 데이터 디렉토리 준비

```bash
# 데이터 디렉토리 생성
sudo mkdir -p /mnt/cryptocur-data/ethereum

# 권한 설정
sudo chown -R 1000:1000 /mnt/cryptocur-data/ethereum
sudo chmod -R 755 /mnt/cryptocur-data/ethereum
```

### 2. Docker Compose로 실행

```bash
# 이미지 빌드 및 컨테이너 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 컨테이너 상태 확인
docker-compose ps
```

### 3. 노드 상태 확인

```bash
# Geth 동기화 상태 확인
docker-compose exec ethereum ./geth attach --exec 'eth.syncing'

# Geth 최신 블록 번호
docker-compose exec ethereum ./geth attach --exec 'eth.blockNumber'

# Prysm 동기화 상태 확인
curl http://localhost:3500/eth/v1/node/syncing

# Prysm 피어 정보
curl http://localhost:3500/eth/v1/node/peers
```

## Dockerfile 설명

### 기본 구조
- **베이스 이미지**: Ubuntu 24.04 LTS
- **Geth 버전**: 1.16.7-b9f3a3d9 (geth-alltools)
  - **최신 버전 확인**: [https://github.com/ethereum/go-ethereum/releases](https://github.com/ethereum/go-ethereum/releases)
- **Prysm 버전**: 7.1.2
  - **최신 버전 확인**: [https://github.com/prysmaticlabs/prysm/releases](https://github.com/prysmaticlabs/prysm/releases)
- **사용자**: cryptocurrency (비root 사용자)
- **작업 디렉토리**: /opt/ethereum
- **데이터 디렉토리**: /var/lib/coindata

### 주요 특징
- Geth와 Prysm 통합 설치
- geth-alltools 사용 (모든 도구 포함)
- JWT secret 자동 생성
- launcher.sh 스크립트로 두 레이어 자동 실행
- gosu를 사용한 안전한 사용자 전환

### 포트
- **30303**: Geth P2P 네트워크 (TCP/UDP)
- **3001**: Geth Engine API (Prysm과 통신)
- **3002**: Geth HTTP-RPC
- **13000**: Prysm P2P 네트워크 (TCP/UDP)
- **4000**: Prysm gRPC
- **3500**: Prysm HTTP-RPC

## docker-compose 사용

### 환경 변수 설정

`.env` 파일을 생성하여 환경 변수를 설정할 수 있습니다:

```bash
# .env 파일
# 네트워크 모드: mainnet (기본값), goerli, sepolia
MODE=mainnet

# Geth P2P 포트
P2PPORT=30303

# 최대 피어 연결 수
MAXPEERS=25
```

### 네트워크 모드

#### 메인넷 (기본값)
```bash
MODE=mainnet docker-compose up -d
# 또는
docker-compose up -d  # 기본값이 mainnet
```

#### Goerli 테스트넷
```bash
MODE=goerli docker-compose up -d
```

#### Sepolia 테스트넷
```bash
MODE=sepolia docker-compose up -d
```

### 데이터 디렉토리 설정

기본적으로 `/mnt/cryptocur-data/ethereum` 디렉토리를 사용합니다. 다른 경로를 사용하려면:

```bash
# docker-compose.yml에서 직접 수정
volumes:
  - /your/custom/path:/var/lib/coindata
```

## 환경 변수 설정

### 필수 환경 변수
- `P2PPORT`: Geth P2P 포트 (기본값: 30303)

### 선택 환경 변수
- `MODE`: 네트워크 모드
  - `mainnet` (기본값): Ethereum 메인넷
  - `goerli`: Goerli 테스트넷
  - `sepolia`: Sepolia 테스트넷
- `MAXPEERS`: 최대 피어 연결 수 (기본값: 25)

## 데이터 관리

### 데이터 백업

```bash
# 컨테이너 중지
docker-compose stop

# 데이터 디렉토리 백업
tar -czf ethereum-backup-$(date +%Y%m%d).tar.gz /mnt/cryptocur-data/ethereum

# 컨테이너 재시작
docker-compose start
```

### 데이터 복원

```bash
# 컨테이너 중지
docker-compose stop

# 백업에서 복원
tar -xzf ethereum-backup-YYYYMMDD.tar.gz -C /mnt/cryptocur-data/

# 컨테이너 재시작
docker-compose start
```

### 데이터 디렉토리 크기 확인

```bash
# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/ethereum

# 디렉토리별 크기 확인
du -h --max-depth=1 /mnt/cryptocur-data/ethereum | sort -hr
```

## 문제 해결

### 컨테이너가 시작되지 않음

```bash
# 로그 확인
docker-compose logs ethereum

# 컨테이너 상태 확인
docker-compose ps -a

# 포트 충돌 확인
netstat -tlnp | grep 30303
netstat -tlnp | grep 13000
```

### Geth 동기화 문제

```bash
# Geth 동기화 상태 확인
docker-compose exec ethereum ./geth attach --exec 'eth.syncing'

# 최신 블록 번호 확인
docker-compose exec ethereum ./geth attach --exec 'eth.blockNumber'

# 피어 연결 수 확인
docker-compose exec ethereum ./geth attach --exec 'net.peerCount'
```

### Prysm 동기화 문제

```bash
# Prysm 동기화 상태 확인
curl http://localhost:3500/eth/v1/node/syncing

# Prysm 피어 정보 확인
curl http://localhost:3500/eth/v1/node/peers

# Prysm 로그 확인
docker-compose logs ethereum | grep -i prysm
```

### Engine API 연결 실패

```bash
# JWT secret 확인
docker-compose exec ethereum ls -la jwt.hex

# Engine API 포트 확인
docker-compose exec ethereum netstat -tlnp | grep 3001

# Geth Engine API 테스트
curl -X POST http://localhost:3001 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### 디스크 공간 부족

```bash
# 데이터 디렉토리 크기 확인
du -sh /mnt/cryptocur-data/ethereum

# 불필요한 로그 파일 정리
docker-compose exec ethereum find /var/lib/coindata -name "*.log" -delete
```

## 유용한 명령어

### 컨테이너 관리
```bash
# 컨테이너 시작
docker-compose up -d

# 컨테이너 중지
docker-compose stop

# 컨테이너 재시작
docker-compose restart

# 컨테이너 제거 (데이터는 유지됨)
docker-compose down

# 컨테이너 및 볼륨 제거 (주의: 데이터 삭제됨)
docker-compose down -v
```

### 로그 확인
```bash
# 실시간 로그
docker-compose logs -f

# 최근 100줄
docker-compose logs --tail=100

# 특정 시간 이후 로그
docker-compose logs --since 1h

# Geth 로그만
docker-compose logs -f | grep -i geth

# Prysm 로그만
docker-compose logs -f | grep -i prysm
```

### Geth Console 사용
```bash
# Geth 콘솔 접속
docker-compose exec ethereum ./geth attach

# 명령어 직접 실행
docker-compose exec ethereum ./geth attach --exec 'eth.blockNumber'
docker-compose exec ethereum ./geth attach --exec 'net.peerCount'
docker-compose exec ethereum ./geth attach --exec 'eth.syncing'
```

### Prysm API 사용
```bash
# 동기화 상태
curl http://localhost:3500/eth/v1/node/syncing

# 피어 정보
curl http://localhost:3500/eth/v1/node/peers

# 노드 정보
curl http://localhost:3500/eth/v1/node/identity

# 최신 블록
curl http://localhost:3500/eth/v1/beacon/blocks/head
```

## 보안 권장사항

1. **포트 노출 제한**: RPC 포트는 localhost로만 노출
2. **Engine API 보안**: Engine API(3001)는 내부 통신용으로만 사용
3. **JWT Secret**: 자동 생성되며 컨테이너 내부에서만 사용
4. **방화벽**: 호스트 방화벽 설정
5. **정기 업데이트**: Geth와 Prysm 최신 버전 유지
6. **백업**: 정기적인 데이터 백업

## 추가 리소스

### Execution Layer (Geth)
- [Geth 공식 문서](https://geth.ethereum.org/docs)
- [Geth GitHub 릴리스](https://github.com/ethereum/go-ethereum/releases)
- [Geth 다운로드 페이지](https://geth.ethereum.org/downloads)

### Consensus Layer (Prysm)
- [Prysm 공식 문서](https://docs.prylabs.network/)
- [Prysm GitHub 릴리스](https://github.com/prysmaticlabs/prysm/releases)

### Docker
- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
