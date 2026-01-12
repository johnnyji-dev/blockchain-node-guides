# launcher.sh 없이 실행하는 방법

`launcher.sh` 스크립트 파일 없이 Docker Compose만으로 Ethereum 노드를 실행하는 방법입니다.

## 방법 1: 인라인 스크립트 사용 (권장)

`docker-compose-no-launcher.yml` 파일을 사용합니다. 이 방법은 모든 로직을 docker-compose.yml의 `command` 섹션에 인라인으로 작성합니다.

### 사용 방법

```bash
# docker-compose-no-launcher.yml 사용
docker-compose -f docker-compose-no-launcher.yml up -d

# 로그 확인
docker-compose -f docker-compose-no-launcher.yml logs -f

# 중지
docker-compose -f docker-compose-no-launcher.yml down
```

### 장점
- 별도의 스크립트 파일이 필요 없음
- 모든 설정이 docker-compose.yml에 집중됨
- 단일 컨테이너로 실행

### 단점
- docker-compose.yml 파일이 길어짐
- 스크립트 수정이 번거로움

## 방법 2: 두 서비스로 분리

`docker-compose-separate.yml` 파일을 사용합니다. Geth와 Prysm을 별도의 서비스로 분리하여 실행합니다.

### 사용 방법

```bash
# docker-compose-separate.yml 사용
docker-compose -f docker-compose-separate.yml up -d

# 로그 확인
docker-compose -f docker-compose-separate.yml logs -f

# Geth 로그만
docker-compose -f docker-compose-separate.yml logs -f geth

# Prysm 로그만
docker-compose -f docker-compose-separate.yml logs -f prysm

# 중지
docker-compose -f docker-compose-separate.yml down
```

### 장점
- 각 서비스를 독립적으로 관리 가능
- Geth와 Prysm을 개별적으로 재시작 가능
- 로그 분리가 쉬움
- 서비스별 리소스 제한 설정 가능

### 단점
- 두 개의 컨테이너가 필요
- JWT secret 공유를 위한 볼륨 설정 필요
- 네트워크 설정이 복잡해질 수 있음

## 환경 변수 설정

두 방법 모두 동일한 환경 변수를 사용합니다:

```bash
# .env 파일 생성
cat > .env << EOF
# 네트워크 모드: mainnet (기본값), goerli, sepolia
MODE=mainnet

# Geth P2P 포트
P2PPORT=30303

# 최대 피어 연결 수
MAXPEERS=25
EOF
```

또는 직접 환경 변수로 설정:

```bash
MODE=mainnet P2PPORT=30303 MAXPEERS=25 docker-compose -f docker-compose-no-launcher.yml up -d
```

## 방법 비교

| 항목 | 방법 1 (인라인) | 방법 2 (분리) |
|------|----------------|--------------|
| 컨테이너 수 | 1개 | 2개 |
| 파일 관리 | 단순 | 복잡 |
| 독립 관리 | 불가능 | 가능 |
| 리소스 제한 | 전체만 가능 | 개별 가능 |
| 로그 분리 | 어려움 | 쉬움 |
| 권장 사용 | 단순한 설정 | 프로덕션 환경 |

## 기존 launcher.sh 방식과의 차이

### launcher.sh 사용 (기존)
```bash
docker-compose up -d
```

### 인라인 스크립트 (방법 1)
```bash
docker-compose -f docker-compose-no-launcher.yml up -d
```

### 서비스 분리 (방법 2)
```bash
docker-compose -f docker-compose-separate.yml up -d
```

## 문제 해결

### 방법 1에서 Geth가 시작되지 않는 경우

```bash
# 로그 확인
docker-compose -f docker-compose-no-launcher.yml logs ethereum

# 컨테이너 재시작
docker-compose -f docker-compose-no-launcher.yml restart ethereum
```

### 방법 2에서 Prysm이 Geth를 찾지 못하는 경우

```bash
# 네트워크 확인
docker network inspect docker_ethereum-network

# Geth 서비스 확인
docker-compose -f docker-compose-separate.yml ps geth

# JWT secret 확인
docker-compose -f docker-compose-separate.yml exec prysm ls -la /opt/ethereum/jwt/
```

## 권장 사항

- **개발/테스트 환경**: 방법 1 (인라인 스크립트) - 단순하고 관리가 쉬움
- **프로덕션 환경**: 방법 2 (서비스 분리) - 독립적인 관리와 모니터링 가능

## 추가 참고

- 기존 `launcher.sh` 방식을 사용하려면 `docker-compose.yml`을 사용하세요
- 모든 방법은 동일한 기능을 제공합니다
- 환경 변수 설정은 모든 방법에서 동일합니다
