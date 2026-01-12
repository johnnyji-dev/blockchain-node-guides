#!/bin/bash

# 오류 발생시 스크립트 진행 종료
set -e

# 외부 변수 입력 확인
if [ -z "$P2PPORT" ]; then 
    echo 'P2PPORT envvar is required' && exit 1
fi

# Prysm, Geth 옵션 설정
MAXPEERS=${MAXPEERS:-25}
MODE=${MODE:-mainnet}
GENESIS_URL=''
PRYSM_OPTIONS=''
GETH_OPTIONS=''

if [ "$MODE" = "mainnet" ] || [ "$MODE" = "" ]; then
    GENESIS_URL='https://github.com/eth-clients/eth2-networks/raw/master/shared/mainnet/genesis.ssz'
    PRYSM_OPTIONS="--mainnet --checkpoint-sync-url=https://beaconstate.info --genesis-beacon-api-url=https://beaconstate.info"
    GETH_OPTIONS='--mainnet --syncmode snap --gcmode archive --cache 16000'
elif [ "$MODE" = "goerli" ]; then
    GENESIS_URL='https://github.com/eth-clients/eth2-networks/raw/master/shared/prater/genesis.ssz'
    PRYSM_OPTIONS="--${MODE}"
    GETH_OPTIONS="--${MODE} --syncmode snap --gcmode archive"
elif [ "$MODE" = "sepolia" ]; then
    GENESIS_URL='https://github.com/eth-clients/merge-testnets/raw/main/sepolia/genesis.ssz'
    PRYSM_OPTIONS="--terminal-total-difficulty-override 17000000000000000 --${MODE} --checkpoint-sync-url=https://checkpoint-sync.sepolia.ethpandaops.io --genesis-beacon-api-url=https://checkpoint-sync.sepolia.ethpandaops.io/"
    GETH_OPTIONS="--${MODE} --syncmode snap --gcmode archive"
fi

# genesis.ssz 다운로드
if [ ! -f "genesis.ssz" ]; then
    echo "Downloading genesis.ssz from ${GENESIS_URL}"
    wget -O genesis.ssz ${GENESIS_URL}
fi

# JWT secret 생성 (Geth와 Prysm 간 통신용)
# 파일이 없거나 비어있으면 생성
if [ ! -f "jwt.hex" ] || [ ! -s "jwt.hex" ]; then
    echo "Generating JWT secret..."
    ./beacon-chain generate-auth-secret --output-file jwt.hex
    chmod 664 jwt.hex
fi

# 폴더 권한 설정
set +e
chown -R $DAEMONUSER:$DAEMONUSER $WORKDIR
chown -R $DAEMONUSER:$DAEMONUSER $DATADIR
# JWT secret 소유권도 설정
chown $DAEMONUSER:$DAEMONUSER jwt.hex 2>/dev/null || true
set -e

# Geth 실행
echo "Starting Geth with options: ${GETH_OPTIONS}"
gosu $DAEMONUSER ./geth $GETH_OPTIONS \
    --maxpeers=$MAXPEERS \
    --datadir $DATADIR \
    --port $P2PPORT \
    --log.rotate \
    --authrpc.vhosts=localhost --authrpc.port=3001 --authrpc.jwtsecret jwt.hex \
    --http --http.addr=0.0.0.0 --http.port=3002 --http.corsdomain=* --http.vhosts=* --http.api debug,web3,eth,txpool,net \
    --txpool.globalslots 65536 --txpool.accountslots 65536 --txpool.globalqueue 65536 --txpool.accountqueue 65536 \
    --txlookuplimit=2350000 &
PID1=$!

# Geth 실행 완료까지 대기
echo "Waiting for Geth to be ready..."
while true; do
    sleep 10
    
    # Engine API 엔드포인트 확인
    http_status=$(curl -IsS --head "http://localhost:3001" 2>/dev/null | head -n 1 | cut -d' ' -f2)
    
    # http_status가 비어있거나 숫자가 아닐 경우 기본값 설정
    if [[ ! "$http_status" =~ ^[0-9]+$ ]]; then
        http_status=0
    fi
    
    if (( http_status >= 100 && http_status < 500 )); then
        echo "Geth is ready (HTTP Status $http_status)."
        break
    fi
    
    # Geth 프로세스가 종료되었는지 확인
    if ! kill -0 $PID1 2>/dev/null; then
        echo "Geth process has exited. Check logs for errors."
        exit 1
    fi
done

# Prysm 실행
echo "Starting Prysm Beacon Chain with options: ${PRYSM_OPTIONS}"
gosu $DAEMONUSER ./beacon-chain $PRYSM_OPTIONS \
    --datadir $DATADIR \
    --execution-endpoint=http://localhost:3001 \
    --jwt-secret=jwt.hex \
    --genesis-state=genesis.ssz \
    --accept-terms-of-use &
PID2=$!

# 안전종료 설정
trap "echo 'Shutting down...'; kill -INT $PID2 2>/dev/null; sleep 5; kill -INT $PID1 2>/dev/null; sleep 5; kill -9 $PID1 $PID2 2>/dev/null; exit 0" TERM INT

# 프로세스 작업 완료 대기
wait $PID1
wait $PID2
