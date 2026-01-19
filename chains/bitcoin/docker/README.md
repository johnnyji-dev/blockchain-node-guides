# Bitcoin 노드 Docker 가이드

Docker를 사용하여 Bitcoin Core 노드를 실행하는 방법입니다.

## 빠른 시작

### 1. 설정 파일 준비

```bash
# 설정 파일 예제 복사
cp bitcoin.conf.example bitcoin.conf

# RPC 비밀번호 변경 (필수!)
nano bitcoin.conf
# rpcpassword를 안전한 비밀번호로 변경
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

#### Docker 컨테이너 상태

```bash
# 컨테이너 상태 확인
docker ps -a

# 컨테이너 리소스 사용량 확인
docker stats bitcoin-node

# 컨테이너 로그 확인
docker logs -f bitcoin-node
```

#### Bitcoin 노드 상태 확인

```bash
# 컨테이너 내부에서 실행
docker-compose exec bitcoind bitcoin-cli getblockchaininfo

# 또는 호스트에서 직접 실행 (RPC 포트가 노출된 경우)
bitcoin-cli -rpcuser=bitcoin -rpcpassword=your_password -rpcport=8332 getblockchaininfo
```

#### 주요 상태 확인 명령어

```bash
# 블록체인 정보 (동기화 상태, 블록 높이 등)
docker exec bitcoin-node bitcoin-cli getblockchaininfo

# 네트워크 정보 (피어 연결 수 등)
docker exec bitcoin-node bitcoin-cli getnetworkinfo

# 피어 연결 상태
docker exec bitcoin-node bitcoin-cli getpeerinfo

# 현재 블록 높이 확인
docker exec bitcoin-node bitcoin-cli getblockcount

# 동기화 완료 여부 확인
docker exec bitcoin-node bitcoin-cli getblockchaininfo | grep -E "blocks|verificationprogress"
```

#### 헬스체크 상태 확인

```bash
# 헬스체크 상태 확인 (unhealthy 상태 진단 시 유용)
docker inspect --format='{{json .State.Health}}' bitcoin-node | jq

# 헬스체크 실패 시 RPC 응답 확인
docker exec bitcoin-node bitcoin-cli getblockchaininfo
```

## 파일 구조

```
docker/
├── Dockerfile              # Docker 이미지 빌드 파일
├── docker-compose.yml      # Docker Compose 설정
├── bitcoin.conf.example    # 설정 파일 예제
├── docker-readme.md        # 상세 가이드
└── README.md               # 이 파일
```

## 설정 파일 (bitcoin.conf.example)

`bitcoin.conf.example` 파일은 Bitcoin Core 노드의 설정을 정의하는 예제 파일입니다. 이 파일을 `bitcoin.conf`로 복사하여 사용합니다.

### 주요 설정 항목

#### 네트워크 설정
- **메인넷 (기본값)**: 프로덕션 환경에서 사용하는 실제 Bitcoin 네트워크
- **testnet=1**: 테스트 목적으로 사용하는 테스트넷
- **regtest=1**: 로컬 개발 및 테스트용 개인 블록체인

#### P2P 네트워크 설정
- **port=8333**: P2P 네트워크 통신 포트 (메인넷 기본값)
  - 포트 번호를 변경하면 인바운드 연결이 줄어들 수 있습니다
  - 대부분의 노드가 기본 포트(8333)를 기대하므로, 특별한 이유가 없다면 기본값을 유지하는 것이 좋습니다
- **listen=1**: 인바운드 연결 수신 활성화
  - 0으로 설정하면 아웃바운드 연결만 가능 (방화벽이 있는 노드에 유용)
- **maxconnections=125**: 최대 피어 연결 수
  - 더 높은 값은 더 많은 피어를 허용하지만 대역폭과 리소스를 더 많이 소비합니다

#### RPC 설정
- **server=1**: JSON-RPC 서버 활성화 (bitcoin-cli 사용을 위해 필수)
- **rpcbind=0.0.0.0**: RPC 서버 바인딩 주소
  - 127.0.0.1로 설정하면 localhost만 허용 (더 안전)
- **rpcport=8332**: RPC 서버 포트 (메인넷 기본값)
- **rpcuser**: RPC 인증 사용자명
- **rpcpassword**: RPC 인증 비밀번호 (반드시 변경 필요!)
  - 최소 32자 이상의 강력한 비밀번호 사용 권장
- **rpcallowip**: RPC 접근 허용 IP 주소
  - 기본값(127.0.0.1)은 localhost만 허용 (가장 안전)
  - 외부 접근이 필요한 경우 CIDR 표기법 사용 (예: 192.168.1.0/24)

#### 성능 최적화
- **txindex=1**: 트랜잭션 인덱스 활성화
  - txid로 트랜잭션 조회 가능
  - 추가 디스크 공간 필요 (~20GB 이상)
- **dbcache=4500**: 데이터베이스 캐시 크기 (MB)
  - 더 높은 값은 동기화 속도와 쿼리 성능 향상
  - 권장: 4500-8000 MB (사용 가능한 RAM에 따라)
- **maxmempool=300**: 최대 메모리 풀 크기 (MB)
  - 미확인 트랜잭션 저장 공간
  - 트랜잭션 볼륨에 따라 300-1000 MB 권장

#### 블록 필터 인덱스
- **blockfilterindex=1**: 컴팩트 블록 필터 인덱스 활성화 (BIP 157)
  - 경량 클라이언트가 블록을 효율적으로 조회 가능
  - 추가 디스크 공간 필요 (~5-10GB)
  - SPV 지갑 및 블록 탐색기에 유용

#### 로그 설정
- **logtimestamps=1**: 로그에 타임스탬프 추가
- **logips=1**: 로그에 IP 주소 포함
  - 피어 연결 추적 및 네트워크 문제 디버깅에 유용
  - 프라이버시가 중요한 경우 비활성화 가능

### 보안 주의사항

1. **RPC 비밀번호 변경 필수**: `rpcpassword`는 반드시 강력한 비밀번호로 변경해야 합니다
2. **RPC 접근 제한**: `rpcallowip`를 통해 RPC 접근을 필요한 IP만 허용하세요
3. **포트 노출 주의**: RPC 포트(8332)를 인터넷에 노출할 경우 강력한 인증이 필요합니다
4. **기본 포트 사용 권장**: P2P 포트(8333)는 특별한 이유가 없다면 기본값을 유지하는 것이 네트워크 건강에 도움이 됩니다

### 설정 파일 사용 방법

```bash
# 1. 예제 파일을 실제 설정 파일로 복사
cp bitcoin.conf.example bitcoin.conf

# 2. 설정 파일 편집
nano bitcoin.conf

# 3. 필수 변경 사항:
#    - rpcpassword를 안전한 비밀번호로 변경
#    - 필요에 따라 다른 설정 조정
```

더 자세한 설정 옵션은 `bitcoin.conf.example` 파일 내의 주석을 참고하세요.

## 상세 가이드

자세한 내용은 [docs/docker/docker-readme.md](./docs/docker/docker-readme.md)를 참고하세요.

## Localhost 설치

일반 호스트에 직접 설치하는 방법은 [../localhost/installation.md](../localhost/installation.md)를 참고하세요.

