# Docker Compose Down 실패 문제 해결 가이드

`docker-compose down` 실행 시 "permission denied" 오류가 발생하는 경우의 해결 방법입니다.

## 🔍 에러 메시지

```
ERROR: for bitcoin-node  cannot stop container: 8985c54161f9...: permission denied
ERROR: error while removing network: network docker_bitcoin-network has active endpoints
```

## 🔎 원인 분석

### 주요 원인

1. **Docker 권한 문제**
   - Snap Docker 사용 시 권한 문제 발생 가능
   - Docker 그룹 권한 부족

2. **컨테이너가 실행 중**
   - 컨테이너가 완전히 중지되지 않음
   - 프로세스가 종료되지 않음

3. **네트워크 활성 엔드포인트**
   - 컨테이너가 네트워크에 연결되어 있어서 네트워크 제거 불가

## 🔧 해결 방법

### 방법 1: sudo 사용 (가장 빠름)

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker
sudo docker-compose down
```

### 방법 2: 단계별 중지 및 제거

#### 1단계: 컨테이너 중지
```bash
# 컨테이너 중지
sudo docker stop bitcoin-node

# 또는 docker-compose 사용
sudo docker-compose stop
```

#### 2단계: 컨테이너 제거
```bash
# 컨테이너 제거
sudo docker rm bitcoin-node

# 또는 docker-compose 사용
sudo docker-compose rm -f
```

#### 3단계: 네트워크 제거
```bash
# 네트워크 제거
sudo docker network rm docker_bitcoin-network

# 또는 docker-compose 사용
sudo docker-compose down
```

### 방법 3: 강제 종료 후 제거

```bash
# 1. 컨테이너 강제 종료
sudo docker kill bitcoin-node

# 2. 잠시 대기
sleep 2

# 3. 컨테이너 제거
sudo docker rm bitcoin-node

# 4. 네트워크 제거
sudo docker network rm docker_bitcoin-network
```

### 방법 4: Docker 서비스 재시작 후 제거

```bash
# 1. Docker 서비스 재시작
sudo snap restart docker

# 2. 잠시 대기
sleep 3

# 3. docker-compose down
cd ~/blockchain-node-guides/chains/bitcoin/docker
sudo docker-compose down
```

### 방법 5: 모든 리소스 강제 제거

```bash
# 1. 컨테이너 강제 종료 및 제거
sudo docker kill bitcoin-node 2>/dev/null || true
sudo docker rm -f bitcoin-node 2>/dev/null || true

# 2. 네트워크 강제 제거
sudo docker network rm docker_bitcoin-network 2>/dev/null || true

# 3. 확인
docker ps -a | grep bitcoin
docker network ls | grep bitcoin
```

## 🎯 빠른 해결 명령어 (한 번에 실행)

### 옵션 1: sudo 사용 (권장)

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker
sudo docker-compose down
```

### 옵션 2: 단계별 실행

```bash
# 1. 컨테이너 중지
sudo docker stop bitcoin-node

# 2. 컨테이너 제거
sudo docker rm bitcoin-node

# 3. 네트워크 제거
sudo docker network rm docker_bitcoin-network
```

### 옵션 3: 강제 제거

```bash
sudo docker kill bitcoin-node && \
sudo docker rm -f bitcoin-node && \
sudo docker network rm docker_bitcoin-network
```

## 📋 단계별 해결 체크리스트

1. ✅ **컨테이너 상태 확인**
   ```bash
   docker ps -a | grep bitcoin
   ```

2. ✅ **컨테이너 중지**
   ```bash
   sudo docker stop bitcoin-node
   ```

3. ✅ **컨테이너 제거**
   ```bash
   sudo docker rm bitcoin-node
   ```

4. ✅ **네트워크 제거**
   ```bash
   sudo docker network rm docker_bitcoin-network
   ```

5. ✅ **확인**
   ```bash
   docker ps -a | grep bitcoin
   docker network ls | grep bitcoin
   ```

## 🔍 문제 진단

### 1단계: 컨테이너 상태 확인

```bash
# 컨테이너 상태 확인
docker ps -a | grep bitcoin

# 상세 정보 확인
docker inspect bitcoin-node | grep -A 5 State
```

### 2단계: 프로세스 확인

```bash
# 컨테이너 내부 프로세스 확인
docker top bitcoin-node

# 호스트에서 bitcoind 프로세스 확인
ps aux | grep bitcoind
```

### 3단계: 네트워크 확인

```bash
# 네트워크 정보 확인
docker network inspect docker_bitcoin-network

# 네트워크에 연결된 컨테이너 확인
docker network inspect docker_bitcoin-network | grep -A 5 Containers
```

### 4단계: Docker 권한 확인

```bash
# Docker 그룹 확인
groups | grep docker

# Docker socket 권한 확인
ls -l /var/run/docker.sock
# 또는 (Snap Docker)
ls -l /var/snap/docker/common/run/docker.sock
```

## 🛡️ 예방 방법

### 1. Docker 그룹에 사용자 추가

```bash
# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER

# 변경사항 적용 (로그아웃 후 다시 로그인 필요)
newgrp docker

# 또는 재로그인
exit  # SSH 세션 종료 후 다시 접속
```

### 2. 정상 종료 사용

```bash
# 정상 종료 (권장)
docker-compose stop
docker-compose down

# 또는 bitcoind 정상 종료
docker-compose exec bitcoind bitcoin-cli stop
docker-compose down
```

### 3. 권한 문제 해결

```bash
# Docker socket 권한 확인 및 수정 (필요한 경우)
sudo chmod 666 /var/run/docker.sock
# 또는 (Snap Docker)
sudo chmod 666 /var/snap/docker/common/run/docker.sock
```

## 📝 추가 정보

### docker-compose down 옵션

```bash
# 기본 (컨테이너와 네트워크 제거)
docker-compose down

# 볼륨도 함께 제거 (주의: 데이터 삭제됨)
docker-compose down -v

# 이미지도 함께 제거
docker-compose down --rmi all

# 오프라인 컨테이너만 제거
docker-compose down --remove-orphans
```

### Snap Docker vs 일반 Docker

**Snap Docker**:
- 경로: `/var/snap/docker`
- 재시작: `sudo snap restart docker`
- 권한 문제가 더 자주 발생할 수 있음

**일반 Docker**:
- 경로: `/var/lib/docker`
- 재시작: `sudo systemctl restart docker`

## 🎯 권장 해결 순서

1. **우선 시도**: sudo 사용
   ```bash
   sudo docker-compose down
   ```

2. **다음 시도**: 단계별 제거
   ```bash
   sudo docker stop bitcoin-node
   sudo docker rm bitcoin-node
   sudo docker network rm docker_bitcoin-network
   ```

3. **그래도 안 되면**: 강제 제거
   ```bash
   sudo docker kill bitcoin-node
   sudo docker rm -f bitcoin-node
   sudo docker network rm docker_bitcoin-network
   ```

4. **최후의 수단**: Docker 재시작
   ```bash
   sudo snap restart docker
   sudo docker-compose down
   ```

## 결론

**가장 빠른 해결 방법**:

```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker
sudo docker-compose down
```

이 방법으로 대부분의 권한 문제를 해결할 수 있습니다.

**근본적인 해결**: 사용자를 docker 그룹에 추가하여 sudo 없이 사용할 수 있도록 설정하세요.
