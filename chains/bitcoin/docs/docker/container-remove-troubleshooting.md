# Docker 컨테이너 제거 불가 문제 해결 가이드

`docker rm -f` 명령어 실행 시 "permission denied" 오류가 발생하는 경우의 원인 분석 및 해결 방법입니다.

## 🔍 원인 분석

### 오류 메시지
```
Error response from daemon: cannot remove container "861b90c428cd": 
could not kill container: permission denied
```

### 가능한 원인

#### 1. **Snap Docker 권한 문제** (가장 가능성 높음)
- `/var/snap/docker` 경로를 사용 중 → Snap Docker 사용 중
- Snap Docker는 시스템 권한 설정이 다를 수 있음
- 일반 `sudo`로는 권한이 부족할 수 있음

#### 2. **Docker Daemon 권한 문제**
- Docker 그룹 권한 문제
- Docker socket 권한 문제

#### 3. **컨테이너 상태 문제**
- 컨테이너가 특별한 권한으로 실행 중
- 프로세스가 완전히 종료되지 않음
- Namespace 문제

#### 4. **RPC 비밀번호와의 관계** ❌
- **결론**: RPC 비밀번호 문제가 아닙니다
- 컨테이너 제거는 Docker daemon 레벨의 작업
- RPC는 컨테이너 내부 애플리케이션 레벨
- 두 문제는 별개입니다

## 🔧 해결 방법

### 방법 1: Docker Compose 사용 (권장)

가장 안전하고 권장되는 방법:

```bash
# docker-compose.yml이 있는 디렉토리로 이동
cd ~/blockchain-node-guides/chains/bitcoin/docker

# 컨테이너 중지 및 제거
docker-compose down

# 강제 제거 (필요한 경우)
docker-compose down --remove-orphans
```

**장점**:
- 모든 관련 리소스 정리 (컨테이너, 네트워크)
- 권한 문제가 적음
- 설정 파일 기반으로 일관된 관리

### 방법 2: 컨테이너 이름으로 제거

컨테이너 ID 대신 이름 사용:

```bash
# 컨테이너 이름 확인
docker ps -a | grep bitcoin

# 이름으로 중지 및 제거
docker stop bitcoin-node
docker rm bitcoin-node

# 강제 제거
docker rm -f bitcoin-node
```

### 방법 3: Snap Docker 권한 확인 및 수정

Snap Docker를 사용하는 경우:

```bash
# Docker 버전 확인 (snap인지 확인)
docker --version
which docker

# Snap Docker인 경우
# 1. Docker 서비스 재시작
sudo snap restart docker

# 2. 사용자를 docker 그룹에 추가 (필요한 경우)
sudo usermod -aG docker $USER
# 로그아웃 후 다시 로그인

# 3. Docker socket 권한 확인
ls -l /var/run/docker.sock
# 또는 Snap Docker의 경우
ls -l /var/snap/docker/common/run/docker.sock
```

### 방법 4: Docker Daemon 재시작

```bash
# Snap Docker 재시작
sudo snap restart docker

# 또는 시스템 Docker인 경우
sudo systemctl restart docker

# 재시작 후 컨테이너 제거 시도
docker rm -f bitcoin-node
```

### 방법 5: 컨테이너 강제 종료 및 제거

```bash
# 1. 컨테이너 상태 확인
docker ps -a | grep 861b90c428cd

# 2. 컨테이너 중지 (강제)
docker kill bitcoin-node
# 또는
docker kill 861b90c428cd

# 3. 잠시 대기
sleep 2

# 4. 컨테이너 제거
docker rm bitcoin-node
# 또는
docker rm 861b90c428cd

# 5. 그래도 안 되면 Docker 재시작 후 재시도
sudo snap restart docker
docker rm -f bitcoin-node
```

### 방법 6: 시스템 레벨 강제 제거 (최후의 수단)

**⚠️ 주의**: 시스템 레벨 작업이므로 신중하게 진행하세요.

```bash
# 1. Docker 서비스 중지
sudo snap stop docker
# 또는
sudo systemctl stop docker

# 2. 컨테이너 메타데이터 직접 제거 (매우 위험)
# 이 방법은 권장하지 않으며, Docker가 실행 중이 아닐 때만 사용

# 3. Docker 서비스 재시작
sudo snap start docker
# 또는
sudo systemctl start docker

# 4. 컨테이너가 제거되었는지 확인
docker ps -a | grep bitcoin
```

### 방법 7: 모든 컨테이너 정리 (주의!)

**⚠️ 경고**: 모든 중지된 컨테이너가 제거됩니다.

```bash
# 모든 중지된 컨테이너 제거
docker container prune

# 또는 특정 컨테이너만 필터링
docker ps -a --filter "name=bitcoin-node" -q | xargs docker rm -f
```

## 🔍 문제 진단 단계

### 1단계: 컨테이너 상태 확인

```bash
# 컨테이너 상태 확인
docker ps -a | grep bitcoin

# 상세 정보 확인
docker inspect bitcoin-node

# 프로세스 확인
docker top bitcoin-node
```

### 2단계: Docker 권한 확인

```bash
# Docker 그룹 확인
groups | grep docker

# Docker socket 권한 확인
ls -l /var/run/docker.sock
# 또는 (Snap Docker)
ls -l /var/snap/docker/common/run/docker.sock

# Docker 정보 확인
docker info
```

### 3단계: Docker 로그 확인

```bash
# Docker daemon 로그 확인 (Snap)
sudo snap logs docker | tail -50

# 또는 시스템 Docker
sudo journalctl -u docker -n 50
```

### 4단계: 네임스페이스 확인

```bash
# 컨테이너의 네임스페이스 확인
docker inspect bitcoin-node | grep -i pid
PID=$(docker inspect -f '{{.State.Pid}}' bitcoin-node)
sudo ls -l /proc/$PID/ns/
```

## 📋 단계별 해결 체크리스트

1. ✅ **Docker Compose 사용**
   ```bash
   cd ~/blockchain-node-guides/chains/bitcoin/docker
   docker-compose down
   ```

2. ✅ **컨테이너 이름으로 제거**
   ```bash
   docker rm -f bitcoin-node
   ```

3. ✅ **Docker 서비스 재시작**
   ```bash
   sudo snap restart docker
   docker rm -f bitcoin-node
   ```

4. ✅ **강제 종료 후 제거**
   ```bash
   docker kill bitcoin-node
   docker rm bitcoin-node
   ```

5. ✅ **Docker 그룹 확인 및 사용자 추가**
   ```bash
   sudo usermod -aG docker $USER
   # 로그아웃 후 다시 로그인
   ```

## 🎯 권장 해결 순서

1. **우선 시도**: Docker Compose 사용
   ```bash
   docker-compose down
   ```

2. **다음 시도**: 컨테이너 이름으로 제거
   ```bash
   docker rm -f bitcoin-node
   ```

3. **그래도 안 되면**: Docker 서비스 재시작
   ```bash
   sudo snap restart docker
   docker rm -f bitcoin-node
   ```

4. **최후의 수단**: 강제 종료 및 제거
   ```bash
   docker kill bitcoin-node
   sleep 2
   docker rm bitcoin-node
   ```

## 🔒 권한 문제 예방 방법

### 1. 사용자를 Docker 그룹에 추가

```bash
# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER

# 변경사항 적용 (로그아웃 후 다시 로그인 필요)
newgrp docker

# 또는 재로그인
exit  # SSH 세션 종료 후 다시 접속
```

### 2. Docker Compose 사용 권장

- `docker-compose`를 사용하면 권한 문제가 적음
- 설정 파일 기반으로 일관된 관리 가능
- 모든 관련 리소스를 한 번에 정리 가능

### 3. Docker 설정 확인

```bash
# Docker 설정 확인
docker info

# Docker 버전 확인
docker --version
docker-compose --version
```

## 📝 추가 정보

### Snap Docker vs 일반 Docker

**Snap Docker**:
- 경로: `/var/snap/docker`
- 재시작: `sudo snap restart docker`
- 설정 파일: `/var/snap/docker/current/`

**일반 Docker**:
- 경로: `/var/lib/docker`
- 재시작: `sudo systemctl restart docker`
- 설정 파일: `/etc/docker/`

### 컨테이너 제거 관련 명령어 비교

| 명령어 | 설명 | 권장도 |
|--------|------|--------|
| `docker-compose down` | Compose로 생성된 컨테이너 제거 | ⭐⭐⭐⭐⭐ |
| `docker rm -f <name>` | 강제 제거 (이름 사용) | ⭐⭐⭐⭐ |
| `docker rm -f <id>` | 강제 제거 (ID 사용) | ⭐⭐⭐ |
| `docker stop + docker rm` | 중지 후 제거 | ⭐⭐⭐⭐ |
| `docker container prune` | 모든 중지 컨테이너 제거 | ⭐⭐ (주의) |

## 결론

**원인**: RPC 비밀번호 문제가 아니라 **Docker daemon 권한 문제**입니다.

**가장 빠른 해결 방법**:
```bash
cd ~/blockchain-node-guides/chains/bitcoin/docker
docker-compose down
```

이 방법이 가장 안전하고 권장되는 방법입니다.
