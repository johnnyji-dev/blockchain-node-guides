# Ethereum 노드 Docker 가이드

Docker를 사용하여 Geth (Execution Layer)와 Prysm (Consensus Layer)를 통합 실행하는 방법입니다.

## 빠른 시작

### 1. 환경 변수 설정 (선택사항)

```bash
# .env 파일 생성 (선택사항)
cat > .env << EOF
# 네트워크 모드: mainnet (기본값), goerli, sepolia
MODE=mainnet

# Geth P2P 포트
P2PPORT=30303

# 최대 피어 연결 수
MAXPEERS=25
EOF
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

# Geth 최신 블록 번호 확인
docker-compose exec ethereum ./geth attach --exec 'eth.blockNumber'

# Geth 피어 연결 수 확인
docker-compose exec ethereum ./geth attach --exec 'net.peerCount'

# Prysm 동기화 상태 확인
curl http://localhost:3500/eth/v1/node/syncing

# Prysm 피어 정보 확인
curl http://localhost:3500/eth/v1/node/peers
```

## 파일 구조

```
docker/
├── Dockerfile              # Docker 이미지 빌드 파일
├── docker-compose.yml      # Docker Compose 설정
├── launcher.sh             # Geth와 Prysm 실행 스크립트
├── docker-readme.md        # 상세 가이드
└── README.md               # 이 파일
```

## Ethereum 노드 구성

이 Docker 설정은 **Execution Layer (Geth)**와 **Consensus Layer (Prysm)**를 모두 포함하는 통합 노드입니다.

### Execution Layer (Geth)
- **공식 릴리스**: [https://github.com/ethereum/go-ethereum/releases](https://github.com/ethereum/go-ethereum/releases)
- **버전**: v1.16.7-b9f3a3d9 (geth-alltools)
- **역할**: 트랜잭션 실행, 상태 관리, 블록 생성
- **포트**: 
  - 30303: P2P 네트워크
  - 3001: Engine API (Prysm과 통신)
  - 3002: HTTP-RPC

### Consensus Layer (Prysm)
- **공식 릴리스**: [https://github.com/prysmaticlabs/prysm/releases](https://github.com/prysmaticlabs/prysm/releases)
- **버전**: v7.1.2
- **역할**: 블록 검증, 합의, 검증자 운영
- **포트**:
  - 13000: P2P 네트워크
  - 4000: gRPC
  - 3500: HTTP-RPC

### Engine API
- Execution Layer와 Consensus Layer 간 통신을 위한 API
- JWT secret을 사용한 인증 (자동 생성됨)
- 포트: 3001 (내부 통신용)

## 환경 변수

### 필수 변수
- `P2PPORT`: Geth P2P 포트 (기본값: 30303)

### 선택 변수
- `MODE`: 네트워크 모드
  - `mainnet` (기본값): 메인넷
  - `goerli`: Goerli 테스트넷
  - `sepolia`: Sepolia 테스트넷
- `MAXPEERS`: 최대 피어 연결 수 (기본값: 25)

## 데이터 저장

블록체인 데이터는 `/mnt/cryptocur-data/ethereum` 디렉토리에 저장됩니다.

### 디렉토리 준비

```bash
# 데이터 디렉토리 생성
sudo mkdir -p /mnt/cryptocur-data/ethereum

# 권한 설정
sudo chown -R 1000:1000 /mnt/cryptocur-data/ethereum
sudo chmod -R 755 /mnt/cryptocur-data/ethereum
```

## 네트워크 모드

### 메인넷 (기본값)
```bash
docker-compose up -d
# 또는
MODE=mainnet docker-compose up -d
```

### Goerli 테스트넷
```bash
MODE=goerli docker-compose up -d
```

### Sepolia 테스트넷
```bash
MODE=sepolia docker-compose up -d
```

## 노드 관리

### 로그 확인
```bash
# 전체 로그
docker-compose logs -f

# Geth 로그만
docker-compose logs -f | grep -i geth

# Prysm 로그만
docker-compose logs -f | grep -i prysm
```

### 노드 중지
```bash
docker-compose stop
```

### 노드 재시작
```bash
docker-compose restart
```

### 노드 제거 (데이터 유지)
```bash
docker-compose down
```

## 보안 주의사항

1. **포트 노출**: RPC 포트는 localhost로만 노출되어 있습니다
2. **JWT Secret**: 자동 생성되며 컨테이너 내부에서만 사용됩니다
3. **방화벽**: P2P 포트(30303, 13000)만 외부에 노출하세요
4. **정기 업데이트**: Geth와 Prysm 최신 버전 유지

## 상세 가이드

자세한 내용은 [docker-readme.md](./docker-readme.md)를 참고하세요.

## Localhost 설치

일반 호스트에 직접 설치하는 방법은 [../localhost/installation.md](../localhost/installation.md)를 참고하세요.
