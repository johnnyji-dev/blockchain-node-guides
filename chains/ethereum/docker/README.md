# Ethereum 노드 Docker 가이드

Docker를 사용하여 Geth 노드를 실행하는 방법입니다.

## 빠른 시작

### 1. 설정 파일 준비

```bash
# 설정 파일 예제 복사
cp geth.toml.example geth.toml

# 설정 파일 편집 (선택사항)
nano geth.toml
# 필요에 따라 설정 조정
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
# 컨테이너 내부에서 실행
docker-compose exec geth geth attach --exec 'eth.syncing'

# 동기화 상태 확인
docker-compose exec geth geth attach --exec 'eth.blockNumber'

# 피어 연결 수 확인
docker-compose exec geth geth attach --exec 'net.peerCount'
```

## 파일 구조

```
docker/
├── Dockerfile              # Docker 이미지 빌드 파일
├── docker-compose.yml      # Docker Compose 설정
├── geth.toml.example       # 설정 파일 예제
├── docker-readme.md        # 상세 가이드
└── README.md               # 이 파일
```

## 설정 파일 (geth.toml.example)

`geth.toml.example` 파일은 Geth 노드의 설정을 정의하는 예제 파일입니다. 이 파일을 `geth.toml`로 복사하여 사용합니다.

### 주요 설정 항목

#### 네트워크 설정
- **메인넷 (기본값)**: 프로덕션 환경에서 사용하는 실제 Ethereum 네트워크
- **테스트넷**: Goerli, Sepolia 등 테스트 목적으로 사용하는 테스트넷

#### P2P 네트워크 설정
- **Port=30303**: P2P 네트워크 통신 포트
  - 포트 번호를 변경하면 인바운드 연결이 줄어들 수 있습니다
  - 대부분의 노드가 기본 포트(30303)를 기대하므로, 특별한 이유가 없다면 기본값을 유지하는 것이 좋습니다
- **MaxPeers=50**: 최대 피어 연결 수
  - 더 높은 값은 더 많은 피어를 허용하지만 대역폭과 리소스를 더 많이 소비합니다

#### HTTP-RPC 설정
- **HTTP.Enabled=true**: HTTP-RPC 서버 활성화 (web3, eth API 사용을 위해 필수)
- **HTTP.Addr=0.0.0.0**: HTTP-RPC 서버 바인딩 주소
  - 127.0.0.1로 설정하면 localhost만 허용 (더 안전)
- **HTTP.Port=8545**: HTTP-RPC 서버 포트 (기본값)
- **HTTP.APIs**: 허용할 RPC API 목록
  - eth, net, web3: 기본 API
  - admin, debug: 관리 및 디버깅 API (보안 주의)

#### WebSocket-RPC 설정
- **WS.Enabled=true**: WebSocket-RPC 서버 활성화
- **WS.Port=8546**: WebSocket-RPC 서버 포트 (기본값)
- **WS.APIs**: 허용할 WebSocket API 목록

#### 성능 최적화
- **Cache=4096**: 캐시 크기 (MB)
  - 더 높은 값은 동기화 속도와 쿼리 성능 향상
  - 권장: 4096-8192 MB (사용 가능한 RAM에 따라)
- **SyncMode=snap**: 동기화 모드
  - snap: 빠른 동기화 (권장)
  - full: 전체 동기화 (느리지만 완전함)
  - light: 경량 동기화 (제한적 기능)

### 보안 주의사항

1. **RPC 접근 제한**: HTTP-RPC와 WebSocket-RPC는 localhost로만 노출하는 것이 좋습니다
2. **API 제한**: admin, debug API는 필요한 경우에만 활성화하세요
3. **포트 노출 주의**: RPC 포트를 인터넷에 노출할 경우 추가 보안 조치가 필요합니다
4. **기본 포트 사용 권장**: P2P 포트(30303)는 특별한 이유가 없다면 기본값을 유지하는 것이 네트워크 건강에 도움이 됩니다

### 설정 파일 사용 방법

```bash
# 1. 예제 파일을 실제 설정 파일로 복사
cp geth.toml.example geth.toml

# 2. 설정 파일 편집 (선택사항)
nano geth.toml

# 3. 필요에 따라 설정 조정
```

더 자세한 설정 옵션은 `geth.toml.example` 파일 내의 주석을 참고하세요.

## 상세 가이드

자세한 내용은 [docker-readme.md](./docker-readme.md)를 참고하세요.

## Localhost 설치

일반 호스트에 직접 설치하는 방법은 [../localhost/installation.md](../localhost/installation.md)를 참고하세요.
