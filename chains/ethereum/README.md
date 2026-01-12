# Ethereum 노드 가이드

Ethereum 노드 설치 및 운영에 대한 종합 가이드입니다.

## Ethereum 노드 구성

Ethereum은 PoS(Proof of Stake)로 전환되어 두 가지 레이어로 구성됩니다:

### 1. Execution Layer (실행 레이어)
- **Geth**: Ethereum 실행 클라이언트
- **공식 릴리스**: [https://github.com/ethereum/go-ethereum/releases](https://github.com/ethereum/go-ethereum/releases)
- **최신 버전**: v1.16.7 (2024년 11월 기준)
- **역할**: 트랜잭션 실행, 상태 관리, 블록 생성

### 2. Consensus Layer (합의 레이어)
- **Prysm**: Ethereum 합의 클라이언트
- **공식 릴리스**: [https://github.com/prysmaticlabs/prysm/releases](https://github.com/prysmaticlabs/prysm/releases)
- **최신 버전**: v7.1.2 (2026년 1월 기준)
- **역할**: 블록 검증, 합의, 검증자 운영

**참고**: 완전한 Ethereum 노드를 운영하려면 Execution Layer와 Consensus Layer를 모두 실행해야 합니다.

## 설치 방법 선택

Ethereum 노드를 실행하는 방법은 두 가지가 있습니다:

### 1. Localhost 설치 (호스트에 직접 설치)

호스트 시스템에 직접 Geth를 설치하고 실행하는 방법입니다.

**장점:**
- 시스템 리소스를 직접 제어
- 더 나은 성능 (가상화 오버헤드 없음)
- 시스템 서비스로 관리 가능

**시작하기:** [localhost/README.md](./localhost/README.md)

### 2. Docker 설치 (컨테이너로 실행)

Docker를 사용하여 Geth를 컨테이너로 실행하는 방법입니다.

**장점:**
- 간편한 설치 및 관리
- 시스템과 격리된 환경
- 쉽게 재배포 및 백업
- 여러 버전 동시 실행 가능

**시작하기:** [docker/README.md](./docker/README.md)

## 폴더 구조

```
ethereum/
├── README.md                    # 이 파일
├── localhost/                    # 호스트 직접 설치 가이드
│   ├── README.md
│   ├── installation.md           # 설치 가이드
│   ├── configuration.md           # 설정 가이드
│   ├── troubleshooting.md        # 트러블슈팅 가이드
│   └── updates/                  # 업데이트 로그
│       └── README.md
└── docker/                       # Docker 설치 가이드
    ├── README.md
    ├── Dockerfile                # Docker 이미지 빌드 파일
    ├── docker-compose.yml        # Docker Compose 설정
    ├── docker-readme.md          # 상세 Docker 가이드
    ├── geth.toml.example         # 설정 파일 예제
    └── .dockerignore             # Docker 빌드 제외 파일
```

## 하드웨어 요구사항

### 최소 사양
- **CPU**: 4코어 이상
- **RAM**: 8GB 이상
- **디스크**: 1TB 이상 (SSD 강력 권장)
- **네트워크**: 안정적인 인터넷 연결 (최소 100Mbps)

### 권장 사양
- **CPU**: 8코어 이상
- **RAM**: 16GB 이상
- **디스크**: 2TB 이상 SSD
- **네트워크**: 광대역 인터넷 연결 (500Mbps 이상)

## 빠른 시작

### Localhost 설치
```bash
cd localhost
# installation.md 참고
```

### Docker 설치
```bash
cd docker
docker-compose up -d
```

## 추가 리소스

### Execution Layer (Geth)
- [Geth 공식 문서](https://geth.ethereum.org/docs)
- [Geth GitHub 릴리스](https://github.com/ethereum/go-ethereum/releases)
- [Geth 다운로드 페이지](https://geth.ethereum.org/downloads)

### Consensus Layer (Prysm)
- [Prysm 공식 문서](https://docs.prylabs.network/)
- [Prysm GitHub 릴리스](https://github.com/prysmaticlabs/prysm/releases)

### 일반 리소스
- [Ethereum Stack Exchange](https://ethereum.stackexchange.com/)
- [Ethereum 공식 웹사이트](https://ethereum.org/)
