# Bitcoin Docker 문서 (통합본)

`chains/bitcoin/docs/docker/`에 흩어져 있던 Docker 관련 문서를 **운영/트러블슈팅 중심으로 통합**한 문서입니다.

> **중요**: 현재 `chains/bitcoin/docker/docker-compose.yml`은 **RPC(8332)를 전체 인터페이스로 노출**하도록 변경되어 있을 수 있습니다.  
> 외부 RPC가 필요 없다면 `127.0.0.1:8332:8332`로 되돌리거나, 반드시 `rpcallowip`/방화벽(UFW)로 접근을 제한하세요.

## 빠른 시작

### 1) 데이터 디렉토리 준비 (호스트)

```bash
sudo mkdir -p /mnt/cryptocur-data/bitcoin

# 컨테이너 내부 bitcoin 유저 UID로 권한 맞추기(권장)
BITCOIN_UID=$(docker run --rm docker_bitcoind id -u bitcoin)
sudo chown -R $BITCOIN_UID:$BITCOIN_UID /mnt/cryptocur-data/bitcoin
sudo chmod -R 755 /mnt/cryptocur-data/bitcoin
```

### 2) 설정 파일 준비

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker
cp bitcoin.conf.example bitcoin.conf
nano bitcoin.conf
```

- **필수**: `rpcpassword`는 반드시 강력한 값으로 변경하세요.
- 운영 중에는 `docker-compose.yml`의 `BITCOIN_RPC_USER`, `BITCOIN_RPC_PASSWORD`(또는 `.env`)와 `bitcoin.conf`의 RPC 값이 **서로 충돌하지 않도록** 한 군데에서만 관리하는 것을 권장합니다. (자세한 내용은 `RPC.md` 참고)

### 3) 실행/중지

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker

# 시작(빌드 포함)
docker-compose up -d

# 로그
docker-compose logs -f

# 중지(컨테이너/네트워크 정리)
docker-compose down
```

## 운영 체크리스트

### 컨테이너 상태/리소스

```bash
docker ps -a
docker stats bitcoin-node
docker logs -f bitcoin-node
```

### 노드 상태 확인(컨테이너 내부)

```bash
docker-compose exec bitcoind bitcoin-cli getblockchaininfo
docker-compose exec bitcoind bitcoin-cli getnetworkinfo
docker-compose exec bitcoind bitcoin-cli getconnectioncount
```

### 헬스체크(unhealthy) 확인

```bash
docker inspect --format='{{json .State.Health}}' bitcoin-node | jq
```

#### unhealthy가 자주 뜰 때(핵심 원인)
- **원인 1**: 헬스체크가 RPC 인증(쿠키/유저·비번)을 못 맞춰서 실패
- **원인 2**: `bitcoin.conf`와 `docker-compose.yml`의 RPC 인증이 충돌
- **원인 3**: RPC 접근 제한(`rpcallowip`)이 헬스체크 소스 IP를 막음

> 현재 `docker-compose.yml`에 쿠키 기반 헬스체크가 들어있다면(예: `-rpccookiefile=/home/bitcoin/.bitcoin/.cookie`) **가장 우선으로 쿠키를 사용**하는 구성이 안정적입니다.

## 자주 겪는 문제 & 해결(실효적인 순서)

### 1) `docker-compose down` 실패 / `permission denied`

증상 예:
- `cannot stop container ... permission denied`
- `error while removing network ... has active endpoints`

권장 해결 순서:

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker

# 1) 가장 먼저 sudo로 재시도
sudo docker-compose down
```

그래도 안 되면:

```bash
# 2) 단계별 강제 정리
sudo docker stop bitcoin-node || true
sudo docker rm -f bitcoin-node || true

# 3) 네트워크가 꼬였을 때만(프로젝트 네트워크 이름은 환경에 따라 다름)
sudo docker network ls | grep -i bitcoin
# 예: sudo docker network rm docker_bitcoin-network
```

Snap Docker 환경에서 계속 꼬이면(로그에 `snap restart docker` 사용 이력 있음):

```bash
sudo snap restart docker
```

### 2) 컨테이너 제거 실패(`docker rm -f ... permission denied`)

실효적인 순서:
1) **가능하면 compose로 정리**: `sudo docker-compose down`
2) 안 되면 `sudo docker rm -f bitcoin-node`
3) 그래도 안 되면 Docker 데몬 재시작(`sudo snap restart docker` 또는 systemd 환경에 맞는 재시작)

### 3) `Cannot obtain a lock on data directory ...`

의미: 동일 데이터 디렉토리(`/mnt/cryptocur-data/bitcoin`)를 **다른 bitcoind가 이미 사용 중**이거나, 비정상 종료로 **stale lock**이 남은 상태.

실효적인 순서:

```bash
# 1) 다른 bitcoind(컨테이너/호스트)가 떠 있는지 확인
docker ps -a | grep -i bitcoin
ps -ef | grep -E '[b]itcoind'
```

```bash
# 2) 먼저 정상 중지(권장)
cd ~/blockchain-node-guides/chains/bitcoin/docker
docker-compose down
```

bitcoind가 완전히 꺼진 것이 확인되면:

```bash
# 3) stale lock 제거(주의: bitcoind가 완전히 꺼져있을 때만)
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock
sudo rm -f /mnt/cryptocur-data/bitcoin/bitcoind.pid
```

```bash
# 4) 재기동
docker-compose up -d
docker logs -f bitcoin-node
```

### 4) LevelDB/chainstate 손상(`Fatal LevelDB error: Corruption ...`)

핵심:
- `-reindex-chainstate` 또는 `-reindex`로 복구 가능
- **복구가 끝나면 옵션을 반드시 제거**(지속적으로 켜두면 매번 재인덱싱)

권장 절차:

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker
docker-compose down
```

1) `docker-compose.yml`에 `-reindex-chainstate`(또는 `-reindex`) 추가  
2) `docker-compose up -d`  
3) 로그로 진행 상황 확인  
4) 완료 후 옵션 제거 → 재시작

> 현재 `docker-compose.yml`에 이미 `-reindex-chainstate`가 들어있다면, **복구 완료 후 반드시 제거**하세요.

### 4-1) LevelDB LOCK 오류(`.../blocks/index/LOCK: Resource temporarily unavailable`)

증상 예:
- `Fatal LevelDB error: IO error: lock .../blocks/index/LOCK: Resource temporarily unavailable`
- `Error opening block database.`

의미:
- 보통 **이전 bitcoind가 완전히 종료되지 않았거나**, 비정상 종료 후 **LOCK 파일이 남아** 새 프로세스가 DB를 못 여는 상태입니다.

실효적인 순서:

```bash
현상황
ubuntu@node1:~/blockchain-node-guides/chains/bitcoin/docker$ docker logs -f 1a3ed1d78ec0
Error: Cannot obtain a lock on data directory /home/bitcoin/.bitcoin. Bitcoin Core is probably already running.

# 1) 우선 완전 중지 (권장)
cd ~/blockchain-node-guides/chains/bitcoin/docker
docker-compose down

ubuntu@node1:~/blockchain-node-guides/chains/bitcoin/docker$ sudo docker-compose down
Stopping bitcoin-node ... done
Removing bitcoin-node ... done
Removing network docker_bitcoin-network
ubuntu@node1:~/blockchain-node-guides/chains/bitcoin/docker$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
ubuntu@node1:~/blockchain-node-guides/chains/bitcoin/docker$ 

# 2) bitcoind 프로세스가 남아있는지 확인(있으면 먼저 종료)
ps -ef | grep -E '[b]itcoind'
ubuntu@node1:~/blockchain-node-guides/chains/bitcoin/docker$ ps -ef | grep -E '[b]itcoind'
ubuntu     81390       1 99 07:39 ?        03:47:19 bitcoind -printtoconsole -txindex=1 -dbcache=4500 -server=1 -reindex-chainstate -rpcuser=bitcoin -rpcpassword=firpeng -rpcbind=0.0.0.0 -rpcallowip=127.0.0.1 -rpcallowip=172.21.0.0/16
ubuntu@node1:~/blockchain-node-guides/chains/bitcoin/docker$ kill -9 81390
ubuntu@node1:~/blockchain-node-guides/chains/bitcoin/docker$ ps -ef | grep -E '[b]itcoind'
ubuntu@node1:~/blockchain-node-guides/chains/bitcoin/docker$ 

```

bitcoind가 완전히 꺼진 것이 확인되면:

```bash
# 3) LOCK/락 관련 파일 제거(주의: 반드시 bitcoind가 꺼져있을 때만)
sudo rm -f /mnt/cryptocur-data/bitcoin/blocks/index/LOCK
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock
sudo rm -f /mnt/cryptocur-data/bitcoin/bitcoind.pid

# (선택) 남은 LOCK 파일 확인
sudo find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f
ubuntu@node1:~/blockchain-node-guides/chains/bitcoin/docker$ sudo find /mnt/cryptocur-data/bitcoin -name "LOCK" -type f
/mnt/cryptocur-data/bitcoin/indexes/txindex/LOCK
/mnt/cryptocur-data/bitcoin/indexes/blockfilter/basic/db/LOCK
/mnt/cryptocur-data/bitcoin/chainstate/LOCK

# ✅ 참고(중요)
# - 위처럼 LOCK 파일이 "보이는 것" 자체는 정상일 수 있습니다. (LevelDB가 LOCK 파일을 만들어두고, 실제 잠금은 프로세스가 OS 레벨로 잡습니다.)
# - 따라서 bitcoind가 완전히 꺼진 상태에서 다시 기동이 정상적으로 된다면, 나열된 LOCK 파일들을 굳이 추가로 삭제할 필요는 없습니다.
# - 반대로 bitcoind가 꺼져있는데도 동일한 LOCK 관련 오류가 계속 재현되면(= stale lock 의심), 그때 해당 경로의 LOCK 파일을 삭제한 뒤 재시도하세요.
```

```bash
# 4) 재기동
docker-compose up -d
docker logs -f bitcoin-node
```

### 5) RPC 연결 실패(호스트/외부에서)

RPC 관련은 문서가 길어 별도 문서로 통합했습니다.
- **RPC/curl/외부접속/보안/Connection refused**: `RPC.md` 참고
- 특히 **“ping은 되는데 8332만 안 열림”** 케이스는 `RPC.md`의 **0-1 섹션(점검 순서: Docker 포트 매핑 → UFW/iptables → OVH 방화벽)**을 그대로 따라가면 됩니다.

## 빠른 네트워크 점검(외부 RPC/P2P 문제 시)

```bash
# 포트 리스닝 확인
sudo ss -tlnp | egrep ':(8332|8333)\\b' || true

# 방화벽(UFW) 상태
sudo ufw status || true

# 외부에서 RPC 오픈 시(8332) 연결 테스트 예시
# (클라이언트 쪽에서) nc -zv <SERVER_IP> 8332
```

> 외부 RPC를 열었을 때는 **UFW/보안그룹 + rpcallowip**를 함께 제한해야 합니다.

## 문서 구조(통합 후)

- `README.md` (이 파일): Docker 운영/트러블슈팅 통합
- `RPC.md`: RPC 설정/보안/외부접속 + curl 호출 가이드

