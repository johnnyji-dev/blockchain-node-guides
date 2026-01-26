# Stellar 노드 Localhost 설치 가이드

Ubuntu 22.04/24.04 환경에서 Stellar 전체 노드를 호스트에 직접 설치하는 방법입니다.

## 설치 순서

1. [시스템 준비](#1-시스템-준비)
2. [PostgreSQL 설치](#2-postgresql-설치)
3. [stellar-core 설치](#3-stellar-core-설치)
4. [horizon 설치](#4-horizon-설치)
5. [서비스 등록](#5-서비스-등록)

## 1. 시스템 준비

### 1-1. 기본 패키지 업데이트

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git build-essential pkg-config autoconf automake libtool \
  bison flex libpq-dev libunwind-dev parallel sed perl curl wget
```

### 1-2. 컴파일러 설치 (Ubuntu 24.04)

```bash
# clang 설치 (권장)
sudo apt install -y clang-18 libc++-18-dev libc++abi-18-dev

# 또는 gcc 설치
# sudo apt install -y gcc-13 g++-13 cpp-13
```

### 1-3. Rust 설치

stellar-core 빌드에 필요합니다 (1.74 이상).

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# 버전 확인
rustc --version
cargo --version
```

### 1-4. Go 설치

horizon 빌드에 필요합니다.

```bash
# Go 최신 버전 다운로드
wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz

# 설치
sudo tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz
rm go1.23.5.linux-amd64.tar.gz

# PATH 설정
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# 버전 확인
go version
```

## 2. PostgreSQL 설치

### 2-1. PostgreSQL 설치

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql
```

### 2-2. 데이터베이스 및 사용자 생성

```bash
sudo -u postgres psql <<EOF
CREATE USER stellar WITH PASSWORD 'strong_password_here';
CREATE DATABASE stellar_core OWNER stellar;
CREATE DATABASE stellar_horizon OWNER stellar;
GRANT ALL PRIVILEGES ON DATABASE stellar_core TO stellar;
GRANT ALL PRIVILEGES ON DATABASE stellar_horizon TO stellar;
\q
EOF
```

비밀번호는 반드시 강력한 비밀번호로 변경하세요.

### 2-3. 연결 테스트

```bash
psql -h localhost -U stellar -d stellar_core -c "SELECT version();"
```

## 3. stellar-core 설치

### 3-1. 소스 코드 클론

```bash
cd ~
git clone https://github.com/stellar/stellar-core.git
cd stellar-core

# 최신 릴리스로 체크아웃
git checkout v22.0.0

# 서브모듈 초기화
git submodule init
git submodule update
```

### 3-2. 빌드

```bash
# autogen 실행
./autogen.sh

# 환경 변수 설정 (clang 사용 시)
export CC=clang-18
export CXX=clang++-18
export CFLAGS="-O3 -g1 -fno-omit-frame-pointer"
export CXXFLAGS="$CFLAGS -stdlib=libc++"

# configure 및 빌드
./configure --prefix=/usr/local
make -j$(nproc)

# 설치
sudo make install

# 버전 확인
stellar-core --version
```

빌드 시간은 시스템 사양에 따라 20-60분 소요됩니다.

### 3-3. 디렉토리 준비

```bash
# 사용자 생성
sudo useradd -r -m -s /bin/bash stellar

# 디렉토리 생성
sudo mkdir -p /etc/stellar
sudo mkdir -p /var/lib/stellar-core/buckets

# 권한 설정
sudo chown -R stellar:stellar /etc/stellar /var/lib/stellar-core
```

### 3-4. 설정 파일 생성

```bash
# 기본 설정 생성
stellar-core --generate-config > /tmp/stellar-core.cfg

# 설정 파일 편집
sudo nano /etc/stellar/stellar-core.cfg
```

**메인넷 설정 예시:**

```ini
# Database connection
DATABASE="postgresql://dbname=stellar_core host=localhost user=stellar password=strong_password_here"

# HTTP port
HTTP_PORT=11626
PUBLIC_HTTP_PORT=false

# Network settings
NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"

# Peer port
PEER_PORT=11625

# Node settings
NODE_IS_VALIDATOR=false

# Maximum peers
MAX_PEER_CONNECTIONS=30

# Quorum set (using SDF validators)
[QUORUM_SET]
THRESHOLD_PERCENT=51
VALIDATORS=[
  "$sdf_1",
  "$sdf_2",
  "$sdf_3"
]

# History archives
[HISTORY.sdf1]
get="curl -sf https://history.stellar.org/prd/core-live/core_live_001/{0} -o {1}"

[HISTORY.sdf2]
get="curl -sf https://history.stellar.org/prd/core-live/core_live_002/{0} -o {1}"

[HISTORY.sdf3]
get="curl -sf https://history.stellar.org/prd/core-live/core_live_003/{0} -o {1}"

# Validators
[$sdf_1]
HOME_DOMAIN="validator1.stellar.org"
QUALITY="HIGH"

[$sdf_2]
HOME_DOMAIN="validator2.stellar.org"
QUALITY="HIGH"

[$sdf_3]
HOME_DOMAIN="validator3.stellar.org"
QUALITY="HIGH"

# Logging
LOG_FILE_PATH="/var/lib/stellar-core/stellar-core.log"

# Data directory
BUCKET_DIR_PATH="/var/lib/stellar-core/buckets"
```

### 3-5. 데이터베이스 초기화

```bash
sudo -u stellar stellar-core --conf /etc/stellar/stellar-core.cfg new-db
sudo -u stellar stellar-core --conf /etc/stellar/stellar-core.cfg new-hist local
```

### 3-6. 테스트 실행

```bash
# Foreground로 실행 (테스트)
sudo -u stellar stellar-core --conf /etc/stellar/stellar-core.cfg run

# Ctrl+C로 중지
```

## 4. horizon 설치

### 4-1. 소스 코드 클론

```bash
cd ~
git clone https://github.com/stellar/go.git stellar-go
cd stellar-go

# 최신 릴리스로 체크아웃
git checkout horizon-v2.32.0
```

### 4-2. 빌드

```bash
# horizon 빌드
cd services/horizon
go build -o horizon ./cmd/horizon

# 설치
sudo mv horizon /usr/local/bin/horizon

# 권한 설정
sudo chmod +x /usr/local/bin/horizon

# 버전 확인
horizon version
```

### 4-3. 디렉토리 준비

```bash
sudo mkdir -p /var/lib/stellar-horizon
sudo chown -R stellar:stellar /var/lib/stellar-horizon
```

### 4-4. 환경 변수 설정

`/etc/stellar/horizon.env` 파일 생성:

```bash
sudo nano /etc/stellar/horizon.env
```

**내용:**

```bash
DATABASE_URL="postgres://stellar:strong_password_here@localhost/stellar_horizon?sslmode=disable"
STELLAR_CORE_DATABASE_URL="postgres://stellar:strong_password_here@localhost/stellar_core?sslmode=disable"
STELLAR_CORE_URL="http://localhost:11626"
NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
HISTORY_ARCHIVE_URLS="https://history.stellar.org/prd/core-live/core_live_001,https://history.stellar.org/prd/core-live/core_live_002,https://history.stellar.org/prd/core-live/core_live_003"
INGEST=true
PORT=8000
LOG_LEVEL=info
```

### 4-5. 데이터베이스 초기화

```bash
# 환경 변수 로드
source /etc/stellar/horizon.env

# DB 초기화
sudo -u stellar horizon db init
sudo -u stellar horizon db migrate up
```

## 5. 서비스 등록

### 5-1. stellar-core 서비스

`/etc/systemd/system/stellar-core.service` 파일 생성:

```ini
[Unit]
Description=Stellar Core Node
After=network.target postgresql.service
Wants=postgresql.service

[Service]
User=stellar
Group=stellar
Type=simple
ExecStart=/usr/local/bin/stellar-core --conf /etc/stellar/stellar-core.cfg run
Restart=on-failure
RestartSec=10
WorkingDirectory=/var/lib/stellar-core

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stellar-core

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### 5-2. horizon 서비스

`/etc/systemd/system/stellar-horizon.service` 파일 생성:

```ini
[Unit]
Description=Stellar Horizon API Server
After=network.target stellar-core.service postgresql.service
Wants=stellar-core.service postgresql.service

[Service]
User=stellar
Group=stellar
Type=simple
EnvironmentFile=/etc/stellar/horizon.env
ExecStart=/usr/local/bin/horizon serve
Restart=on-failure
RestartSec=10
WorkingDirectory=/var/lib/stellar-horizon

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stellar-horizon

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### 5-3. 서비스 시작

```bash
# systemd 리로드
sudo systemctl daemon-reload

# stellar-core 활성화 및 시작
sudo systemctl enable stellar-core
sudo systemctl start stellar-core
sudo systemctl status stellar-core

# horizon 활성화 및 시작
sudo systemctl enable stellar-horizon
sudo systemctl start stellar-horizon
sudo systemctl status stellar-horizon
```

### 5-4. 로그 확인

```bash
# stellar-core 로그
sudo journalctl -u stellar-core -f

# horizon 로그
sudo journalctl -u stellar-horizon -f

# 파일 로그 (stellar-core)
sudo tail -f /var/lib/stellar-core/stellar-core.log
```

## 6. 노드 상태 확인

### stellar-core 상태

```bash
# HTTP API로 확인
curl http://localhost:11626/info

# 동기화 상태
stellar-core --conf /etc/stellar/stellar-core.cfg http-command 'info'

# 피어 정보
curl http://localhost:11626/peers
```

### horizon 상태

```bash
# API 확인
curl http://localhost:8000/

# 최신 원장
curl http://localhost:8000/ledgers?limit=1&order=desc

# 헬스체크
curl http://localhost:8000/health
```

## 7. 방화벽 설정

```bash
# UFW 설치
sudo apt install -y ufw

# 기본 정책
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH 허용
sudo ufw allow 22

# stellar-core P2P 포트
sudo ufw allow 11625

# 방화벽 활성화
sudo ufw enable
sudo ufw status
```

## 8. 업데이트

### stellar-core 업데이트

```bash
cd ~/stellar-core
git fetch --tags
git checkout v<new-version>
git submodule update
./autogen.sh
./configure --prefix=/usr/local
make -j$(nproc)
sudo systemctl stop stellar-core
sudo make install
sudo systemctl start stellar-core
```

### horizon 업데이트

```bash
cd ~/stellar-go
git fetch --tags
git checkout horizon-v<new-version>
cd services/horizon
go build -o horizon ./cmd/horizon
sudo systemctl stop stellar-horizon
sudo mv horizon /usr/local/bin/horizon
sudo systemctl start stellar-horizon
```

## 문제 해결

### stellar-core가 시작되지 않는 경우

```bash
# 로그 확인
sudo journalctl -u stellar-core -n 100

# 설정 파일 검증
stellar-core --conf /etc/stellar/stellar-core.cfg test

# 데이터베이스 재초기화
sudo -u stellar stellar-core --conf /etc/stellar/stellar-core.cfg new-db
```

### horizon이 시작되지 않는 경우

```bash
# 로그 확인
sudo journalctl -u stellar-horizon -n 100

# 데이터베이스 연결 테스트
psql -h localhost -U stellar -d stellar_horizon -c "SELECT 1;"

# 데이터베이스 재마이그레이션
source /etc/stellar/horizon.env
sudo -u stellar horizon db reingest range 1 <latest_ledger>
```

### 디스크 공간 관리

```bash
# 사용량 확인
du -sh /var/lib/stellar-core
du -sh /var/lib/stellar-horizon

# PostgreSQL 진공 청소
sudo -u postgres psql -d stellar_core -c "VACUUM FULL;"
sudo -u postgres psql -d stellar_horizon -c "VACUUM FULL;"
```

## 참고 자료

- [stellar-core 설치 가이드](https://github.com/stellar/stellar-core/blob/master/INSTALL.md)
- [horizon 설정 가이드](https://github.com/stellar/go/tree/master/services/horizon)
- [Stellar 개발자 문서](https://developers.stellar.org/)
