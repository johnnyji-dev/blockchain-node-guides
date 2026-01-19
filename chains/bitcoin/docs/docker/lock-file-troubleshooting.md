# Bitcoin Core Lock 파일 오류 해결 가이드

## 🔍 에러 원인 분석

### 에러 메시지
```
Error: Cannot obtain a lock on data directory /home/bitcoin/.bitcoin. 
Bitcoin Core is probably already running.
```

### 원인

1. **Lock 파일이 남아있음**
   - 이전 컨테이너가 비정상 종료되어 lock 파일이 남음
   - `/mnt/cryptocur-data/bitcoin/.lock` 파일이 존재
   - `/mnt/cryptocur-data/bitcoin/bitcoind.pid` 파일이 존재

2. **컨테이너 재시작 정책 문제**
   - `restart: unless-stopped` 설정으로 인해 컨테이너가 계속 재시작
   - bitcoind가 시작 실패 → 종료 → 재시작 → 실패 반복

3. **이전 프로세스가 완전히 종료되지 않음**
   - 컨테이너가 종료되었지만 bitcoind 프로세스가 완전히 종료되지 않음
   - PID 파일이 남아있어서 새로운 프로세스가 시작 불가

## 🔧 해결 방법

### 방법 1: Lock 파일 제거 후 재시작 (권장)

#### 1단계: 컨테이너 중지

```bash
# docker-compose 사용 (권장)
cd ~/blockchain-node-guides/chains/bitcoin/docker
docker-compose stop

# 또는 컨테이너 이름으로 중지
docker stop bitcoin-node
```

#### 2단계: Lock 파일 제거

```bash
# 호스트에서 lock 파일 확인
ls -la /mnt/cryptocur-data/bitcoin/.lock
ls -la /mnt/cryptocur-data/bitcoin/bitcoind.pid

# Lock 파일 제거
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock
sudo rm -f /mnt/cryptocur-data/bitcoin/bitcoind.pid

# 또는 모든 lock 관련 파일 확인 및 제거
sudo find /mnt/cryptocur-data/bitcoin -name "*.lock" -o -name "*.pid" | xargs sudo rm -f
```

#### 3단계: 컨테이너 재시작

```bash
# docker-compose 사용
docker-compose up -d

# 또는 컨테이너 시작
docker start bitcoin-node
```

### 방법 2: 컨테이너 내부에서 Lock 파일 제거

#### 1단계: 컨테이너 실행 (실행 중인 경우)

```bash
# 컨테이너가 실행 중이면 내부 접속
docker exec -it bitcoin-node bash
```

#### 2단계: Lock 파일 제거

```bash
# 컨테이너 내부에서
rm -f /home/bitcoin/.bitcoin/.lock
rm -f /home/bitcoin/.bitcoin/bitcoind.pid

# 종료
exit
```

#### 3단계: 컨테이너 재시작

```bash
docker restart bitcoin-node
```

### 방법 3: 컨테이너 완전 제거 후 재생성

#### 1단계: 컨테이너 중지 및 제거

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker

# 컨테이너 중지 및 제거
docker-compose down

# 또는 강제 제거
docker rm -f bitcoin-node
```

#### 2단계: Lock 파일 제거

```bash
# Lock 파일 제거
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock
sudo rm -f /mnt/cryptocur-data/bitcoin/bitcoind.pid
```

#### 3단계: 컨테이너 재생성 및 시작

```bash
docker-compose up -d
```

### 방법 4: 재시작 정책 일시 변경 (임시 해결)

#### 1단계: 재시작 정책 변경

`docker-compose.yml`에서 재시작 정책을 일시적으로 변경:

```yaml
# restart: unless-stopped  # 주석 처리
restart: "no"  # 재시작 안 함
```

또는 명령어로 변경:

```bash
docker update --restart=no bitcoin-node
```

#### 2단계: 컨테이너 중지 및 Lock 파일 제거

```bash
docker stop bitcoin-node
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock
sudo rm -f /mnt/cryptocur-data/bitcoin/bitcoind.pid
```

#### 3단계: 컨테이너 시작 및 재시작 정책 복원

```bash
docker start bitcoin-node

# 재시작 정책 복원
docker update --restart=unless-stopped bitcoin-node
```

## 🔍 문제 진단 단계

### 1단계: 컨테이너 상태 확인

```bash
# 컨테이너 상태 확인
docker ps -a | grep bitcoin

# 컨테이너 로그 확인
docker logs bitcoin-node

# 최근 로그 확인
docker logs --tail=50 bitcoin-node
```

### 2단계: Lock 파일 확인

```bash
# 호스트에서 lock 파일 확인
ls -la /mnt/cryptocur-data/bitcoin/.lock
ls -la /mnt/cryptocur-data/bitcoin/bitcoind.pid

# 컨테이너 내부에서 확인
docker exec bitcoin-node ls -la /home/bitcoin/.bitcoin/.lock
docker exec bitcoin-node ls -la /home/bitcoin/.bitcoin/bitcoind.pid
```

### 3단계: 실행 중인 프로세스 확인

```bash
# 컨테이너 내부 프로세스 확인
docker exec bitcoin-node ps aux | grep bitcoind

# 호스트에서 bitcoind 프로세스 확인
ps aux | grep bitcoind
```

### 4단계: PID 파일 내용 확인

```bash
# PID 파일 내용 확인 (실행 중인 프로세스 ID)
cat /mnt/cryptocur-data/bitcoin/bitcoind.pid

# 해당 PID가 실제로 실행 중인지 확인
ps -p $(cat /mnt/cryptocur-data/bitcoin/bitcoind.pid)
```

## 📋 단계별 해결 체크리스트

1. ✅ **컨테이너 중지**
   ```bash
   docker-compose stop
   ```

2. ✅ **Lock 파일 제거**
   ```bash
   sudo rm -f /mnt/cryptocur-data/bitcoin/.lock
   sudo rm -f /mnt/cryptocur-data/bitcoin/bitcoind.pid
   ```

3. ✅ **컨테이너 재시작**
   ```bash
   docker-compose up -d
   ```

4. ✅ **로그 확인**
   ```bash
   docker-compose logs -f
   ```

## 🎯 빠른 해결 명령어 (한 번에 실행)

```bash
# 1. 컨테이너 중지
cd ~/blockchain-node-guides/chains/bitcoin/docker
docker-compose stop

# 2. Lock 파일 제거
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock /mnt/cryptocur-data/bitcoin/bitcoind.pid

# 3. 컨테이너 재시작
docker-compose up -d

# 4. 로그 확인
docker-compose logs -f
```

## 🔒 Lock 파일이 계속 생성되는 경우

### 원인
- 다른 bitcoind 프로세스가 실행 중
- 여러 컨테이너가 같은 데이터 디렉토리를 사용
- 이전 컨테이너가 완전히 종료되지 않음

### 해결 방법

#### 1. 모든 Bitcoin 컨테이너 확인 및 중지

```bash
# 모든 Bitcoin 관련 컨테이너 확인
docker ps -a | grep bitcoin

# 모든 Bitcoin 컨테이너 중지
docker stop $(docker ps -a | grep bitcoin | awk '{print $1}')

# Lock 파일 제거
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock /mnt/cryptocur-data/bitcoin/bitcoind.pid

# 컨테이너 재시작
docker-compose up -d
```

#### 2. 호스트에서 실행 중인 bitcoind 확인

```bash
# 호스트에서 bitcoind 프로세스 확인
ps aux | grep bitcoind

# 프로세스 종료 (필요한 경우)
sudo killall bitcoind
```

#### 3. 포트 사용 확인

```bash
# 포트 8332, 8333 사용 확인
sudo netstat -tlnp | grep 8332
sudo netstat -tlnp | grep 8333

# 사용 중인 프로세스 종료 (필요한 경우)
sudo kill -9 <PID>
```

## 🛡️ 예방 방법

### 1. 정상 종료 사용

```bash
# 정상 종료 (권장)
docker-compose stop

# 또는 bitcoind 정상 종료
docker-compose exec bitcoind bitcoin-cli stop

# 강제 종료는 피하기
# docker kill bitcoin-node  # 비권장
```

### 2. 재시작 전 Lock 파일 확인 스크립트

`docker-compose.yml`에 추가할 수 있는 스크립트:

```yaml
command:
  - /bin/bash
  - -c
  - |
    # Lock 파일 제거 (이전 프로세스가 완전히 종료되지 않은 경우)
    rm -f /home/bitcoin/.bitcoin/.lock /home/bitcoin/.bitcoin/bitcoind.pid
    # bitcoind 실행
    exec bitcoind -printtoconsole -txindex=1 -dbcache=4500 -server=1 -rpcuser=${BITCOIN_RPC_USER:-bitcoin} -rpcpassword=${BITCOIN_RPC_PASSWORD:-changeme} -rpcbind=0.0.0.0 -rpcallowip=127.0.0.1
```

### 3. 시작 스크립트 생성

`start-bitcoind.sh` 파일 생성:

```bash
#!/bin/bash
# Lock 파일 제거
rm -f /home/bitcoin/.bitcoin/.lock /home/bitcoin/.bitcoin/bitcoind.pid
# bitcoind 실행
exec bitcoind "$@"
```

Dockerfile에 추가:

```dockerfile
COPY start-bitcoind.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-bitcoind.sh
ENTRYPOINT ["start-bitcoind.sh"]
```

## 📝 추가 정보

### Lock 파일이란?

- **`.lock`**: 데이터 디렉토리 잠금 파일
- **`bitcoind.pid`**: 실행 중인 bitcoind 프로세스의 PID 저장
- **목적**: 동시에 여러 bitcoind 인스턴스가 같은 데이터 디렉토리를 사용하는 것을 방지

### Lock 파일 위치

- **컨테이너 내부**: `/home/bitcoin/.bitcoin/.lock`, `/home/bitcoin/.bitcoin/bitcoind.pid`
- **호스트**: `/mnt/cryptocur-data/bitcoin/.lock`, `/mnt/cryptocur-data/bitcoin/bitcoind.pid`

### 안전하게 Lock 파일 제거하는 시점

1. ✅ **컨테이너가 완전히 중지된 후**
2. ✅ **bitcoind 프로세스가 실행 중이 아닐 때**
3. ✅ **데이터베이스 작업이 진행 중이 아닐 때**

### 주의사항

⚠️ **Lock 파일을 제거할 때 주의사항**:
- bitcoind가 실행 중일 때 제거하면 데이터 손상 위험
- 항상 컨테이너를 먼저 중지한 후 제거
- 여러 컨테이너가 같은 데이터를 사용하는 경우 동시 실행 방지

## 결론

**가장 빠른 해결 방법**:

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker
docker-compose stop
sudo rm -f /mnt/cryptocur-data/bitcoin/.lock /mnt/cryptocur-data/bitcoin/bitcoind.pid
docker-compose up -d
```

이 방법으로 대부분의 lock 파일 문제를 해결할 수 있습니다.
