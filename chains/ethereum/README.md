# Ethereum 노드 가이드

Ethereum Geth 노드 설치 및 운영에 대한 종합 가이드입니다.

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

- [Geth 공식 문서](https://geth.ethereum.org/docs)
- [Geth GitHub](https://github.com/ethereum/go-ethereum)
- [Ethereum Stack Exchange](https://ethereum.stackexchange.com/)
