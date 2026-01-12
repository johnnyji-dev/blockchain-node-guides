# Ethereum 노드 설정 가이드

Geth 노드의 설정 및 최적화에 대한 가이드입니다.

## 목차
- [설정 파일 위치](#설정-파일-위치)
- [기본 설정](#기본-설정)
- [네트워크 설정](#네트워크-설정)
- [RPC 설정](#rpc-설정)
- [성능 최적화](#성능-최적화)
- [보안 설정](#보안-설정)

## 설정 파일 위치

Geth의 설정 파일은 다음 위치에 있습니다:

- **Linux**: `~/.ethereum/geth.toml`
- **macOS**: `~/Library/Ethereum/geth.toml`
- **Windows**: `%APPDATA%\Ethereum\geth.toml`

### 설정 파일 생성 방법

#### 방법 1: 예제 파일 사용 (권장)

```bash
# Linux/macOS
cd ~/.ethereum
# 또는
cd ~/Library/Ethereum

# 예제 파일 복사
cp /path/to/geth.toml.example geth.toml

# 설정 파일 편집
nano geth.toml
# 또는
vim geth.toml
```

#### 방법 2: 직접 생성

```bash
# Linux
mkdir -p ~/.ethereum
nano ~/.ethereum/geth.toml

# macOS
mkdir -p ~/Library/Ethereum
nano ~/Library/Ethereum/geth.toml
```

## 기본 설정

### 네트워크 선택

```toml
# 메인넷 (기본값)
# mainnet = true

# 테스트넷
# testnet = "goerli"
# testnet = "sepolia"
```

또는 명령줄 옵션:
```bash
--mainnet        # 메인넷
--goerli         # Goerli 테스트넷
--sepolia        # Sepolia 테스트넷
```

### 데이터 디렉토리

```toml
DataDir = "/home/user/.ethereum"
```

또는 명령줄 옵션:
```bash
--datadir ~/.ethereum
```

## 네트워크 설정

### P2P 포트

```toml
Port = 30303
```

### 최대 피어 수

```toml
MaxPeers = 50
```

또는 명령줄 옵션:
```bash
--maxpeers 50
```

## RPC 설정

### HTTP-RPC

```toml
[HTTP]
Enabled = true
Addr = "127.0.0.1"  # localhost만 허용 (보안)
Port = 8545
APIs = ["eth", "net", "web3", "admin", "debug"]
CorsDomain = ["*"]
VHosts = ["*"]
```

또는 명령줄 옵션:
```bash
--http
--http.addr 127.0.0.1
--http.port 8545
--http.api eth,net,web3,admin,debug
```

### WebSocket-RPC

```toml
[WS]
Enabled = true
Addr = "127.0.0.1"  # localhost만 허용 (보안)
Port = 8546
APIs = ["eth", "net", "web3", "admin", "debug"]
Origins = ["*"]
```

또는 명령줄 옵션:
```bash
--ws
--ws.addr 127.0.0.1
--ws.port 8546
--ws.api eth,net,web3,admin,debug
```

## 성능 최적화

### 캐시 크기

```toml
Cache = 4096  # MB
```

또는 명령줄 옵션:
```bash
--cache 4096
```

**권장값:**
- 최소: 2048 MB
- 권장: 4096-8192 MB (사용 가능한 RAM에 따라)

### 동기화 모드

```toml
SyncMode = "snap"  # snap, full, light
```

또는 명령줄 옵션:
```bash
--syncmode snap    # 빠른 동기화 (권장)
--syncmode full    # 전체 동기화 (느리지만 완전함)
--syncmode light   # 경량 동기화 (제한적 기능)
```

**권장:** snap 모드는 빠르고 효율적이며 대부분의 사용 사례에 적합합니다.

## 보안 설정

### RPC 접근 제한

```toml
[HTTP]
Addr = "127.0.0.1"  # localhost만 허용
APIs = ["eth", "net", "web3"]  # admin, debug 제외
```

### 계정 관리 비활성화

```toml
NoUSB = true
```

또는 명령줄 옵션:
```bash
--nousb
```

### 방화벽 설정

```bash
# UFW 방화벽 설정 예시
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp
# RPC 포트는 외부에 노출하지 않음 (localhost만 사용)
```

## 고급 설정

### 로그 설정

```toml
Verbosity = 3  # 0 (silent) ~ 5 (trace)
```

또는 명령줄 옵션:
```bash
--verbosity 3
```

### 로그 파일

```toml
LogFile = "/home/user/.ethereum/geth.log"
```

## 설정 파일 예제

전체 설정 파일 예제는 [../docker/geth.toml.example](../docker/geth.toml.example)를 참고하세요.

## 다음 단계

설정이 완료되면 노드를 시작하고 [트러블슈팅 가이드](./troubleshooting.md)를 참고하여 문제를 해결하세요.
