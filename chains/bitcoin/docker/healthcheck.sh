#!/bin/bash
# Bitcoin 노드 헬스체크 스크립트
# 환경 변수에서 RPC 인증 정보를 읽어서 헬스체크 수행

# 환경 변수가 설정되지 않은 경우 기본값 사용
RPC_USER=${BITCOIN_RPC_USER:-bitcoin}
RPC_PASSWORD=${BITCOIN_RPC_PASSWORD:-changeme}

# 쿠키 파일이 있으면 우선 사용, 없으면 환경 변수 사용
if [ -f /home/bitcoin/.bitcoin/.cookie ]; then
    bitcoin-cli -rpccookiefile=/home/bitcoin/.bitcoin/.cookie getblockchaininfo > /dev/null 2>&1
else
    bitcoin-cli -rpcuser=${RPC_USER} -rpcpassword=${RPC_PASSWORD} getblockchaininfo > /dev/null 2>&1
fi

exit $?
