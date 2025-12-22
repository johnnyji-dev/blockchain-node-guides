# Bitcoin 노드 Docker 가이드

Docker를 사용하여 Bitcoin Core 노드를 실행하는 방법입니다.

## 목차
- [빠른 시작](#빠른-시작)
- [Dockerfile 설명](#dockerfile-설명)
- [docker-compose 사용](#docker-compose-사용)
- [설정 파일](#설정-파일)
- [데이터 관리](#데이터-관리)
- [문제 해결](#문제-해결)

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

## Dockerfile 설명

### 기본 구조
- **베이스 이미지**: Ubuntu 22.04 LTS
- **Bitcoin 버전**: 26.0 (환경 변수로 변경 가능)
- **사용자**: 비root 사용자(bitcoin)로 실행
- **포트**: 8333 (P2P), 8332 (RPC)

### 주요 특징
- 공식 Bitcoin Core 바이너리 사용
- 보안을 위한 비root 사용자 실행
- 헬스체크 포함
- 볼륨 마운트를 통한 데이터 영구 저장

## docker-compose 사용

### 환경 변수 설정

`.env` 파일을 생성하여 환경 변수를 설정할 수 있습니다:

```bash
# .env 파일
BITCOIN_DATA_PATH=/path/to/bitcoin/data
BITCOIN_RPC_USER=bitcoin
BITCOIN_RPC_PASSWORD=your_secure_password
```

### 데이터 디렉토리 설정

기본적으로 `./data` 디렉토리를 사용합니다. 다른 경로를 사용하려면:

```bash
# 환경 변수로 설정
export BITCOIN_DATA_PATH=/mnt/bitcoin-data

# 또는 docker-compose.yml에서 직접 수정
```

### 리소스 제한

`docker-compose.yml`에서 리소스 제한을 조정할 수 있습니다:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'      # 최대 CPU
      memory: 8G     # 최대 메모리
    reservations:
      cpus: '2'      # 최소 CPU
      memory: 4G     # 최소 메모리
```

## 설정 파일

### 설정 파일 위치

- **컨테이너 내부**: `/home/bitcoin/.bitcoin/bitcoin.conf`
- **호스트**: `./bitcoin.conf` (docker-compose.yml에서 마운트)

### 주요 설정 옵션

#### RPC 보안 설정
```conf
# 로컬호스트만 허용 (권장)
rpcbind=127.0.0.1
rpcallowip=127.0.0.1

# 특정 네트워크 허용
# rpcallowip=192.168.1.0/24
```

#### 성능 최적화
```conf
# 트랜잭션 인덱스 (더 많은 디스크 공간 필요)
txindex=1

# 데이터베이스 캐시 (메모리 사용량 증가)
dbcache=4500
```

## 데이터 관리

### 데이터 백업

```bash
# 컨테이너 중지
docker-compose stop

# 데이터 디렉토리 백업
tar -czf bitcoin-backup-$(date +%Y%m%d).tar.gz ./data

# 컨테이너 재시작
docker-compose start
```

### 데이터 복원

```bash
# 컨테이너 중지
docker-compose stop

# 백업에서 복원
tar -xzf bitcoin-backup-YYYYMMDD.tar.gz

# 컨테이너 재시작
docker-compose start
```

### 데이터 디렉토리 크기 확인

```bash
# 데이터 디렉토리 크기 확인
du -sh ./data

# 또는 컨테이너 내부에서
docker-compose exec bitcoind du -sh /home/bitcoin/.bitcoin
```

## 문제 해결

### 컨테이너가 시작되지 않음

```bash
# 로그 확인
docker-compose logs bitcoind

# 컨테이너 상태 확인
docker-compose ps -a

# 포트 충돌 확인
netstat -tlnp | grep 8333
netstat -tlnp | grep 8332
```

### 동기화 문제

```bash
# 블록체인 정보 확인
docker-compose exec bitcoind bitcoin-cli getblockchaininfo

# 재인덱싱 (시간이 오래 걸림)
docker-compose stop
docker-compose run --rm bitcoind bitcoind -reindex
docker-compose start
```

### RPC 연결 실패

```bash
# RPC 설정 확인
docker-compose exec bitcoind cat /home/bitcoin/.bitcoin/bitcoin.conf | grep rpc

# RPC 테스트
docker-compose exec bitcoind bitcoin-cli getnetworkinfo
```

### 디스크 공간 부족

```bash
# 데이터 디렉토리 크기 확인
du -sh ./data

# 불필요한 로그 파일 정리
docker-compose exec bitcoind find /home/bitcoin/.bitcoin -name "*.log" -delete
```

## 유용한 명령어

### 컨테이너 관리
```bash
# 컨테이너 시작
docker-compose up -d

# 컨테이너 중지
docker-compose stop

# 컨테이너 재시작
docker-compose restart

# 컨테이너 제거 (데이터는 유지됨)
docker-compose down

# 컨테이너 및 볼륨 제거 (주의: 데이터 삭제됨)
docker-compose down -v
```

### 로그 확인
```bash
# 실시간 로그
docker-compose logs -f

# 최근 100줄
docker-compose logs --tail=100

# 특정 시간 이후 로그
docker-compose logs --since 1h
```

### Bitcoin CLI 사용
```bash
# 컨테이너 내부에서 실행
docker-compose exec bitcoind bitcoin-cli getblockchaininfo
docker-compose exec bitcoind bitcoin-cli getnetworkinfo
docker-compose exec bitcoind bitcoin-cli getconnectioncount

# 노드 중지
docker-compose exec bitcoind bitcoin-cli stop
```

## 보안 권장사항

1. **RPC 비밀번호**: 강력한 비밀번호 사용
2. **포트 노출**: RPC 포트는 로컬호스트로만 노출
3. **방화벽**: 호스트 방화벽 설정
4. **정기 업데이트**: Bitcoin Core 최신 버전 유지
5. **백업**: 정기적인 데이터 백업

## 추가 리소스

- [Bitcoin Core 공식 문서](https://bitcoin.org/en/developer-documentation)
- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Compose 문서](https://docs.docker.com/compose/)

