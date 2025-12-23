# Bitcoin 노드 설정 가이드

Bitcoin Core 노드의 설정 및 최적화에 대한 가이드입니다.

## 목차
- [설정 파일 위치](#설정-파일-위치)
- [기본 설정](#기본-설정)
- [네트워크 설정](#네트워크-설정)
- [RPC 설정](#rpc-설정)
- [성능 최적화](#성능-최적화)
- [보안 설정](#보안-설정)

## 설정 파일 위치

Bitcoin Core의 설정 파일은 다음 위치에 있습니다:

- **Linux**: `~/.bitcoin/bitcoin.conf`
- **macOS**: `~/Library/Application Support/Bitcoin/bitcoin.conf`
- **Windows**: `%APPDATA%\Bitcoin\bitcoin.conf`

### 설정 파일 생성 방법

#### 방법 1: 예제 파일 사용 (권장)

```bash
# Linux/macOS
cd ~/.bitcoin
# 또는
cd ~/Library/Application\ Support/Bitcoin

# 예제 파일 복사
cp /path/to/bitcoin.conf.example bitcoin.conf

# 설정 파일 편집 (RPC 비밀번호 필수 변경!)
nano bitcoin.conf
# 또는
vim bitcoin.conf
```

#### 방법 2: 직접 생성

```bash
# Linux
mkdir -p ~/.bitcoin
nano ~/.bitcoin/bitcoin.conf

# macOS
mkdir -p ~/Library/Application\ Support/Bitcoin
nano ~/Library/Application\ Support/Bitcoin/bitcoin.conf
```

**중요**: 설정 파일을 생성한 후 반드시 `rpcpassword`를 안전한 비밀번호로 변경하세요!

### 완전한 설정 파일 예제

완전한 설정 파일 예제는 [bitcoin.conf.example](./bitcoin.conf.example)를 참고하세요.

## 기본 설정 파일 예제

다음은 기본적인 bitcoin.conf 파일 예제입니다:

```conf
# 네트워크 설정
# 메인넷 (기본값)
# testnet=1
# regtest=1

# P2P 네트워크 설정
port=8333
listen=1
maxconnections=125

# RPC 설정 (필수!)
server=1
rpcbind=127.0.0.1
rpcport=8332
rpcuser=bitcoin
rpcpassword=your_secure_password_here  # 반드시 변경하세요!
rpcallowip=127.0.0.1

# 성능 최적화
txindex=1
dbcache=4500
maxmempool=300

# 로그 설정
logtimestamps=1
logips=1
```

**더 자세한 예제는 [bitcoin.conf.example](./bitcoin.conf.example) 파일을 참고하세요.**

### 데이터 디렉토리 설정
```conf
# 데이터 디렉토리 지정 (선택사항)
datadir=/path/to/bitcoin/data
```

### 네트워크 선택
```conf
# 메인넷 (기본값)
# testnet=1
# regtest=1
```

## 네트워크 설정

### 포트 설정
```conf
# P2P 포트 (기본: 8333)
port=8333

# 테스트넷 포트
# testnet.port=18333
```

### 피어 연결
```conf
# 최대 연결 수
maxconnections=125

# 외부 연결 허용
listen=1

# 외부 IP 지정 (선택사항)
# externalip=YOUR_IP_ADDRESS
```

## RPC 설정

### RPC 활성화
```conf
# RPC 서버 활성화
server=1

# RPC 바인딩 주소
rpcbind=127.0.0.1
rpcport=8332

# RPC 사용자명 및 비밀번호
rpcuser=your_username
rpcpassword=your_secure_password

# RPC 허용 IP (선택사항)
# rpcallowip=127.0.0.1
```

### RPC 보안 강화
```conf
# RPC를 로컬호스트로만 제한
rpcbind=127.0.0.1

# 특정 IP만 허용
# rpcallowip=192.168.1.0/24
```

## 성능 최적화

### 데이터베이스 설정
```conf
# 데이터베이스 캐시 크기 (MB)
dbcache=4500

# 트랜잭션 인덱스 유지
txindex=1
```

### 블록 필터링
```conf
# 블록 필터 인덱스 (BIP 157)
blockfilterindex=1
```

### 메모리 최적화
```conf
# 메모리 풀 크기 제한 (MB)
maxmempool=300
```

## 보안 설정

### 방화벽 설정
```bash
# UFW 사용 시
sudo ufw allow 8333/tcp
sudo ufw allow 8333/udp
```

### RPC 보안
```conf
# RPC를 로컬호스트로만 제한
rpcbind=127.0.0.1
rpcallowip=127.0.0.1
```

### 지갑 암호화
```conf
# 지갑 암호화 활성화 (지갑 사용 시)
# encryptwallet=1
```

## systemd 서비스 설정

### 서비스 파일 생성
```bash
sudo tee /etc/systemd/system/bitcoind.service > /dev/null <<EOF
[Unit]
Description=Bitcoin Core Daemon
After=network.target

[Service]
Type=forking
User=bitcoin
Group=bitcoin
ExecStart=/usr/local/bin/bitcoind -daemon -pid=/run/bitcoind/bitcoind.pid
PIDFile=/run/bitcoind/bitcoind.pid
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
```

### 서비스 활성화
```bash
sudo systemctl daemon-reload
sudo systemctl enable bitcoind
sudo systemctl start bitcoind
```

## 설정 확인

```bash
# 설정 파일 검증
bitcoin-cli -conf=/path/to/bitcoin.conf getnetworkinfo

# 현재 설정 확인
bitcoin-cli getnetworkinfo
bitcoin-cli getblockchaininfo
```

## 문제 해결

설정 관련 문제가 발생하면 [트러블슈팅 가이드](./troubleshooting.md)를 참고하세요.

