#!/bin/bash

# 오류 발생시 스크립트 진행 종료
set -e

# 환경 변수 확인
NETWORK=${NETWORK:-public}
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_USER=${POSTGRES_USER:-stellar}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-stellarpassword}
CORE_DB=${CORE_DB:-stellar_core}
HORIZON_DB=${HORIZON_DB:-stellar_horizon}
HORIZON_PORT=${HORIZON_PORT:-8000}
INGEST=${INGEST:-true}

echo "Starting Stellar Node..."
echo "Network: $NETWORK"
echo "PostgreSQL Host: $POSTGRES_HOST"

# 네트워크별 설정
if [ "$NETWORK" = "public" ] || [ "$NETWORK" = "mainnet" ]; then
    NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
    HISTORY_ARCHIVE_URLS='["https://history.stellar.org/prd/core-live/core_live_001","https://history.stellar.org/prd/core-live/core_live_002","https://history.stellar.org/prd/core-live/core_live_003"]'
    CAPTIVE_CORE_PEER_PORT=11625
elif [ "$NETWORK" = "testnet" ]; then
    NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
    HISTORY_ARCHIVE_URLS='["https://history.stellar.org/prd/core-testnet/core_testnet_001","https://history.stellar.org/prd/core-testnet/core_testnet_002"]'
    CAPTIVE_CORE_PEER_PORT=11625
else
    echo "Unknown network: $NETWORK"
    exit 1
fi

# PostgreSQL 연결 대기
echo "Waiting for PostgreSQL..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d postgres -c '\q'; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "PostgreSQL is up!"

# Horizon 데이터베이스 생성
echo "Creating Horizon database if not exists..."
PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$HORIZON_DB'" | grep -q 1 || \
PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE $HORIZON_DB OWNER $POSTGRES_USER"

# stellar-core 설정 파일 생성
echo "Generating stellar-core configuration..."
cat > $WORKDIR/stellar-core.cfg << 'EOF'
# Stellar Core Configuration

DATABASE="postgresql://dbname=stellar_core host=postgres user=stellar password=stellarpassword"

# HTTP port for commands
HTTP_PORT=11626
PUBLIC_HTTP_PORT=true

# Network settings
NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"

# Peer port
PEER_PORT=11625

# Node settings
NODE_IS_VALIDATOR=false

# Quorum set (using SDF validators for public network)
[QUORUM_SET]
THRESHOLD_PERCENT=67
VALIDATORS=[
"$sdf1",
"$sdf2", 
"$sdf3"
]

# History archives
[HISTORY.sdf1]
get="curl -sf https://history.stellar.org/prd/core-live/core_live_001/{0} -o {1}"

[HISTORY.sdf2]
get="curl -sf https://history.stellar.org/prd/core-live/core_live_002/{0} -o {1}"

[HISTORY.sdf3]
get="curl -sf https://history.stellar.org/prd/core-live/core_live_003/{0} -o {1}"

# SDF Validators
[VALIDATOR."$sdf1"]
NAME="sdf1"
HOME_DOMAIN="www.stellar.org"
PUBLIC_KEY="GCGB2S2KGYARPVIA37HYZXVRM2YZUEXA6S33ZU5BUDC6THSB62LZSTYH"
ADDRESS="core-live-a.stellar.org"
HISTORY="curl -sf https://history.stellar.org/prd/core-live/core_live_001/{0} -o {1}"

[VALIDATOR."$sdf2"]
NAME="sdf2"
HOME_DOMAIN="www.stellar.org"
PUBLIC_KEY="GCM6QMP3DLRPTAZW2UZPCPX2LF3SXWXKPMP3GKFZBDSF3QZGV2G5QSTK"
ADDRESS="core-live-b.stellar.org"
HISTORY="curl -sf https://history.stellar.org/prd/core-live/core_live_002/{0} -o {1}"

[VALIDATOR."$sdf3"]
NAME="sdf3"
HOME_DOMAIN="www.stellar.org"
PUBLIC_KEY="GABMKJM6I25XI4K7U6XWMULOUQIQ27BCTMLS6BYYSOWKTBUXVRJSXHYQ"
ADDRESS="core-live-c.stellar.org"
HISTORY="curl -sf https://history.stellar.org/prd/core-live/core_live_003/{0} -o {1}"

# Logging
LOG_FILE_PATH=""

# Data directory
BUCKET_DIR_PATH="/var/lib/stellar/core/buckets"
EOF

# 환경 변수로 대체
sed -i "s|stellar_core|$CORE_DB|g" $WORKDIR/stellar-core.cfg
sed -i "s|postgres user=stellar password=stellarpassword|$POSTGRES_HOST user=$POSTGRES_USER password=$POSTGRES_PASSWORD|g" $WORKDIR/stellar-core.cfg
sed -i "s|Public Global Stellar Network ; September 2015|$NETWORK_PASSPHRASE|g" $WORKDIR/stellar-core.cfg

# 폴더 권한 설정
chown -R $DAEMONUSER:$DAEMONUSER $WORKDIR $DATADIR 2>/dev/null || true

# stellar-core 데이터베이스 초기화 (최초 실행시만)
if [ ! -f "$DATADIR/core/.initialized" ]; then
    echo "Initializing stellar-core database..."
    gosu $DAEMONUSER stellar-core --conf $WORKDIR/stellar-core.cfg new-db
    gosu $DAEMONUSER stellar-core --conf $WORKDIR/stellar-core.cfg new-hist local
    touch "$DATADIR/core/.initialized"
    echo "stellar-core database initialized"
fi

# stellar-core 실행
echo "Starting stellar-core..."
gosu $DAEMONUSER stellar-core --conf $WORKDIR/stellar-core.cfg run &
CORE_PID=$!

# stellar-core 실행 완료까지 대기
echo "Waiting for stellar-core to be ready..."
for i in {1..60}; do
    sleep 5
    
    if curl -sf http://localhost:11626/info > /dev/null 2>&1; then
        echo "stellar-core is ready!"
        break
    fi
    
    if ! kill -0 $CORE_PID 2>/dev/null; then
        echo "stellar-core process has exited. Check logs for errors."
        exit 1
    fi
    
    echo "Waiting for stellar-core... ($i/60)"
done

# Horizon 데이터베이스 초기화
echo "Initializing Horizon database..."
export DATABASE_URL="postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST/$HORIZON_DB?sslmode=disable"
export STELLAR_CORE_DATABASE_URL="postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST/$CORE_DB?sslmode=disable"
export STELLAR_CORE_URL="http://localhost:11626"
export NETWORK_PASSPHRASE="$NETWORK_PASSPHRASE"
export INGEST=$INGEST
export PORT=$HORIZON_PORT
export HISTORY_ARCHIVE_URLS=$HISTORY_ARCHIVE_URLS
export CAPTIVE_CORE_CONFIG_PATH=$WORKDIR/stellar-core.cfg
export ENABLE_CAPTIVE_CORE_INGESTION=false

# Horizon 데이터베이스 마이그레이션 (최초 실행시만)
if [ ! -f "$DATADIR/horizon/.initialized" ]; then
    echo "Running Horizon database migrations..."
    gosu $DAEMONUSER horizon db init
    gosu $DAEMONUSER horizon db migrate up
    touch "$DATADIR/horizon/.initialized"
    echo "Horizon database initialized"
fi

# Horizon 실행
echo "Starting Horizon..."
gosu $DAEMONUSER horizon serve &
HORIZON_PID=$!

# 안전종료 설정
trap "echo 'Shutting down...'; kill -INT $HORIZON_PID 2>/dev/null; sleep 5; kill -INT $CORE_PID 2>/dev/null; sleep 5; kill -9 $CORE_PID $HORIZON_PID 2>/dev/null; exit 0" TERM INT

# 프로세스 작업 완료 대기
wait $CORE_PID
wait $HORIZON_PID
