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

```bash
# 컨테이너 내부에서 실행
docker-compose exec bitcoind bitcoin-cli getblockchaininfo

# 또는 호스트에서 직접 실행 (RPC 포트가 노출된 경우)
bitcoin-cli -rpcuser=bitcoin -rpcpassword=your_password -rpcport=8332 getblockchaininfo
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

## 상세 가이드

자세한 내용은 [docker-readme.md](./docker-readme.md)를 참고하세요.

## Localhost 설치

일반 호스트에 직접 설치하는 방법은 [../localhost/installation.md](../localhost/installation.md)를 참고하세요.

