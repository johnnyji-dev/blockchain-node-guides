# 블록체인 노드 가이드

블록체인 네트워크의 노드 운영에 대한 종합 가이드 및 정보 정리 프로젝트입니다.

**Languages**: [한국어](#한국어) | [English](#english)

<a name="한국어"></a>
## 1. 블록체인 노드가 하는 역할

블록체인 노드는 블록체인 네트워크의 핵심 구성 요소로, 다음과 같은 중요한 역할을 수행합니다:

### 데이터 저장 및 동기화
- **블록체인 데이터 저장**: 네트워크의 모든 블록과 트랜잭션을 로컬에 저장하여 완전한 블록체인 사본을 유지합니다
- **네트워크 동기화**: 다른 노드들과 지속적으로 통신하여 최신 블록체인 상태를 동기화합니다
- **데이터 검증**: 받은 블록과 트랜잭션의 유효성을 암호학적으로 검증합니다

### 네트워크 유지 및 참여
- **피어 연결**: 다른 노드들과 P2P 네트워크를 형성하여 분산 네트워크를 유지합니다
- **데이터 전파**: 새로운 블록과 트랜잭션을 네트워크의 다른 노드들에게 브로드캐스트합니다
- **합의 알고리즘 실행**: 네트워크의 합의 규칙에 따라 블록 생성에 참여하거나 검증을 수행합니다

### 서비스 제공
- **RPC API 제공**: 외부 애플리케이션이 블록체인 데이터에 접근할 수 있도록 RPC 인터페이스를 제공합니다
- **트랜잭션 제출**: 사용자가 트랜잭션을 제출하고 네트워크에 전파할 수 있는 인터페이스를 제공합니다
- **지갑 기능**: 일부 노드는 지갑 기능을 내장하여 사용자의 자산을 관리하고 트랜잭션을 서명할 수 있습니다

## 2. 블록체인 노드가 필요한 이유

### 탈중앙화 보장
- **중앙 집중화 방지**: 블록체인의 핵심 가치인 탈중앙화를 실현하기 위해 수많은 독립적인 노드가 필요합니다
- **단일 장애점 제거**: 단일 서버에 의존하지 않아 네트워크의 안정성과 가용성이 향상됩니다
- **검열 저항성**: 네트워크에 충분한 노드가 존재할수록 외부의 검열이나 통제에 저항할 수 있습니다

### 네트워크 보안
- **분산 검증**: 많은 노드가 독립적으로 블록을 검증함으로써 네트워크의 보안이 강화됩니다
- **공격 저항성**: 51% 공격과 같은 악의적인 공격을 방어하기 위해 충분한 노드가 필요합니다
- **데이터 무결성**: 여러 노드에 분산 저장된 데이터의 무결성을 보장합니다

### 개발 및 운영 필요성
- **독립적인 검증**: 서드파티 서비스에 의존하지 않고 직접 블록체인 데이터를 검증할 수 있습니다
- **프라이버시 보호**: 자체 노드를 운영함으로써 트랜잭션 정보를 외부에 노출하지 않습니다
- **성능 및 안정성**: 자체 노드를 통해 더 빠르고 안정적인 서비스를 제공할 수 있습니다
- **비용 절감**: 외부 RPC 서비스 이용 비용을 절감할 수 있습니다

## 3. 블록체인 노드의 종류

### 풀 노드 (Full Node)
- **특징**: 블록체인의 모든 블록과 트랜잭션 데이터를 저장하고 검증합니다
- **장점**: 완전한 독립성과 보안, 네트워크에 큰 기여
- **단점**: 높은 저장 공간과 네트워크 대역폭 요구, 초기 동기화 시간이 길음
- **용도**: 네트워크 보안 강화, 완전한 검증, 개발 및 운영

### 아카이브 노드 (Archive Node)
- **특징**: 풀 노드의 모든 기능 + 모든 이전 상태 정보를 저장합니다
- **장점**: 과거의 모든 상태를 조회할 수 있음
- **단점**: 매우 큰 저장 공간 필요 (수 TB 이상)
- **용도**: 블록 탐색기, 인덱싱 서비스, 복잡한 쿼리 수행

### 라이트 노드 (Light Node / SPV Node)
- **특징**: 블록 헤더만 저장하고 풀 노드에 의존합니다
- **장점**: 적은 저장 공간과 빠른 동기화
- **단점**: 독립적인 검증 불가, 다른 노드에 의존
- **용도**: 모바일 지갑, 간단한 트랜잭션 확인

### 밸리데이터 노드 (Validator Node)
- **특징**: 합의 알고리즘에 참여하여 새로운 블록을 생성합니다 (PoS, DPoS 등)
- **장점**: 블록 생성 보상 획득 가능, 네트워크에 직접 기여
- **단점**: 높은 하드웨어 요구사항, 자금 스테이킹 필요 (PoS의 경우)
- **용도**: 블록 생성, 네트워크 합의 참여

### RPC 노드 (Remote Procedure Call Node)
- **특징**: 외부 애플리케이션에 RPC 인터페이스를 제공하는 노드
- **장점**: 개발자 친화적, 다양한 API 제공
- **단점**: 추가 보안 고려 필요
- **용도**: DApp 개발, 블록체인 데이터 조회

### 부트스트랩 노드 (Bootstrap Node)
- **특징**: 네트워크에 처음 접속하는 노드에게 초기 연결 정보를 제공합니다
- **장점**: 네트워크 진입 장벽 감소
- **단점**: 항상 온라인 상태 유지 필요
- **용도**: 네트워크 진입점 제공

## 4. 본 프로젝트에서 목표

이 프로젝트는 다양한 블록체인 네트워크의 노드 설치, 운영, 관리에 대한 실용적인 가이드를 제공하는 것을 목표로 합니다.

### 4.1. 블록체인 노드 설치 및 설정 방법

각 블록체인 네트워크별로 상세한 설치 및 설정 가이드를 제공합니다:

- **하드웨어 요구사항**: CPU, RAM, 디스크, 네트워크 대역폭
- **소프트웨어 요구사항**: 운영체제, 필수 패키지, 의존성
- **단계별 설치 절차**: 바이너리 설치, 소스 빌드, 패키지 관리자 활용
- **설정 파일 구성**: 네트워크 설정, RPC 설정, P2P 설정
- **초기 동기화 가이드**: 빠른 동기화 방법, 스냅샷 활용
- **서비스 설정**: systemd 서비스 구성, 자동 재시작 설정
- **보안 설정**: 방화벽 구성, RPC 접근 제한, SSL/TLS 설정

각 블록체인별로 별도의 디렉토리와 문서를 제공하여 체계적으로 관리합니다.

### 4.2. 블록체인 노드 버전 업데이트 내용 정리

블록체인 노드 소프트웨어의 업데이트 내역을 체계적으로 정리합니다:

- **업데이트 히스토리**: 버전별 변경 사항, 릴리스 노트
- **주요 기능 추가**: 새로운 기능 및 개선 사항
- **버그 수정**: 해결된 이슈 및 보안 패치
- **하위 호환성**: 이전 버전과의 호환성 정보
- **마이그레이션 가이드**: 업데이트 시 필요한 절차 및 주의사항
- **성능 개선**: 최적화 및 성능 향상 내역

업데이트 시 노드 운영자들이 쉽게 참고하고 적용할 수 있도록 구성합니다.

### 4.3. 블록체인 노드 이슈 정리

노드 운영 중 발생하는 일반적인 문제와 해결 방법을 정리합니다:

- **일반적인 오류**: 자주 발생하는 에러 메시지와 해결 방법
- **동기화 문제**: 동기화 실패, 느린 동기화, 포크 발생 등
- **성능 이슈**: 높은 CPU/메모리 사용률, 디스크 I/O 병목
- **네트워크 문제**: 피어 연결 실패, 포트 문제, 방화벽 설정
- **데이터 손상**: 체크섬 오류, 데이터베이스 복구
- **업데이트 후 이슈**: 버전 업데이트 후 발생하는 문제
- **하드웨어 관련**: 디스크 공간 부족, 메모리 부족

각 이슈별로 증상, 원인, 해결 방법을 체계적으로 문서화합니다.

### 4.4. 대상 블록체인

**CMC 상위 50개 메인넷을 시작으로 점차 늘려갈 예정**

초기 목표는 CoinMarketCap(CMC)에서 시가총액 기준 상위 50개의 메인넷 블록체인에 대한 가이드를 제공하는 것입니다. 이후 점진적으로 대상 블록체인을 확대하여 더 많은 네트워크를 지원할 계획입니다.

#### 우선순위 기준
- **시가총액**: CMC 기준 시가총액 순위
- **활성도**: 네트워크 활동 및 거래량
- **커뮤니티**: 개발자 및 사용자 커뮤니티 규모
- **생태계**: DApp 및 서비스 생태계의 성숙도

#### 포함 예정 블록체인 (예시)
- Bitcoin (BTC)
- Ethereum (ETH)
- Binance Smart Chain (BSC)
- Solana (SOL)
- Cardano (ADA)
- Polkadot (DOT)
- Avalanche (AVAX)
- Polygon (MATIC)
- Cosmos (ATOM)
- ... (상위 50개)

각 블록체인마다 다음 정보를 제공합니다:
- 노드 설치 가이드 (`/chains/[chain-name]/installation.md`)
- 설정 가이드 (`/chains/[chain-name]/configuration.md`)
- 업데이트 로그 (`/chains/[chain-name]/updates/`)
- 이슈 및 트러블슈팅 (`/chains/[chain-name]/troubleshooting.md`)

## 프로젝트 구조

```
blockchain-node-guides/
├── README.md
├── chains/
│   ├── bitcoin/
│   │   ├── installation.md
│   │   ├── configuration.md
│   │   ├── updates/
│   │   └── troubleshooting.md
│   ├── ethereum/
│   │   ├── installation.md
│   │   ├── configuration.md
│   │   ├── updates/
│   │   └── troubleshooting.md
│   └── ...
└── common/
    ├── hardware-requirements.md
    └── security-best-practices.md
```

## 기여 방법

이 프로젝트는 커뮤니티의 기여를 환영합니다:

1. 새로운 블록체인 가이드 추가
2. 기존 가이드의 개선 및 업데이트
3. 이슈 리포트 및 버그 수정
4. 문서 번역 및 개선

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 문의

프로젝트에 대한 문의사항이나 제안사항이 있으시면 이슈를 등록해 주세요.

---

<a name="english"></a>
# English

## Blockchain Node Guide

A comprehensive guide and information repository project for operating nodes in blockchain networks.

## 1. Roles of Blockchain Nodes

Blockchain nodes are core components of blockchain networks and perform the following important roles:

### Data Storage and Synchronization
- **Blockchain Data Storage**: Stores all blocks and transactions of the network locally to maintain a complete copy of the blockchain
- **Network Synchronization**: Continuously communicates with other nodes to synchronize the latest blockchain state
- **Data Validation**: Cryptographically validates the validity of received blocks and transactions

### Network Maintenance and Participation
- **Peer Connections**: Forms P2P networks with other nodes to maintain a distributed network
- **Data Propagation**: Broadcasts new blocks and transactions to other nodes in the network
- **Consensus Algorithm Execution**: Participates in block creation or performs validation according to the network's consensus rules

### Service Provision
- **RPC API Provision**: Provides RPC interfaces for external applications to access blockchain data
- **Transaction Submission**: Provides interfaces for users to submit transactions and propagate them to the network
- **Wallet Functionality**: Some nodes have built-in wallet functionality to manage user assets and sign transactions

## 2. Why Blockchain Nodes Are Needed

### Decentralization Guarantee
- **Preventing Centralization**: Numerous independent nodes are needed to realize decentralization, a core value of blockchain
- **Eliminating Single Points of Failure**: Not depending on a single server improves network stability and availability
- **Censorship Resistance**: The more nodes exist in the network, the more resistant it becomes to external censorship or control

### Network Security
- **Distributed Validation**: Network security is strengthened as many nodes independently validate blocks
- **Attack Resistance**: Sufficient nodes are needed to defend against malicious attacks such as 51% attacks
- **Data Integrity**: Ensures the integrity of data stored across multiple nodes

### Development and Operational Necessity
- **Independent Validation**: Can directly validate blockchain data without depending on third-party services
- **Privacy Protection**: Operating your own node prevents exposing transaction information to external parties
- **Performance and Stability**: Can provide faster and more stable services through your own node
- **Cost Reduction**: Can reduce costs of using external RPC services

## 3. Types of Blockchain Nodes

### Full Node
- **Characteristics**: Stores and validates all blocks and transaction data of the blockchain
- **Advantages**: Complete independence and security, significant contribution to the network
- **Disadvantages**: High storage space and network bandwidth requirements, long initial synchronization time
- **Use Cases**: Network security enhancement, complete validation, development and operations

### Archive Node
- **Characteristics**: All features of a full node + stores all historical state information
- **Advantages**: Can query all past states
- **Disadvantages**: Requires very large storage space (several TB or more)
- **Use Cases**: Block explorers, indexing services, complex queries

### Light Node / SPV Node
- **Characteristics**: Stores only block headers and depends on full nodes
- **Advantages**: Low storage space and fast synchronization
- **Disadvantages**: Cannot perform independent validation, depends on other nodes
- **Use Cases**: Mobile wallets, simple transaction verification

### Validator Node
- **Characteristics**: Participates in consensus algorithms to create new blocks (PoS, DPoS, etc.)
- **Advantages**: Can earn block creation rewards, directly contributes to the network
- **Disadvantages**: High hardware requirements, requires staking funds (for PoS)
- **Use Cases**: Block creation, network consensus participation

### RPC Node (Remote Procedure Call Node)
- **Characteristics**: Node that provides RPC interfaces to external applications
- **Advantages**: Developer-friendly, provides various APIs
- **Disadvantages**: Requires additional security considerations
- **Use Cases**: DApp development, blockchain data queries

### Bootstrap Node
- **Characteristics**: Provides initial connection information to nodes first accessing the network
- **Advantages**: Reduces network entry barriers
- **Disadvantages**: Must remain online at all times
- **Use Cases**: Network entry point provision

## 4. Project Goals

This project aims to provide practical guides for installing, operating, and managing nodes for various blockchain networks.

### 4.1. Blockchain Node Installation and Configuration Methods

Provides detailed installation and configuration guides for each blockchain network:

- **Hardware Requirements**: CPU, RAM, disk, network bandwidth
- **Software Requirements**: Operating system, essential packages, dependencies
- **Step-by-Step Installation Procedures**: Binary installation, source builds, package manager usage
- **Configuration File Setup**: Network settings, RPC settings, P2P settings
- **Initial Synchronization Guide**: Fast synchronization methods, snapshot utilization
- **Service Configuration**: systemd service setup, automatic restart configuration
- **Security Settings**: Firewall configuration, RPC access restrictions, SSL/TLS settings

Each blockchain is managed systematically with separate directories and documents.

### 4.2. Blockchain Node Version Update Documentation

Systematically organizes update history of blockchain node software:

- **Update History**: Version-specific changes, release notes
- **Major Feature Additions**: New features and improvements
- **Bug Fixes**: Resolved issues and security patches
- **Backward Compatibility**: Compatibility information with previous versions
- **Migration Guide**: Procedures and precautions needed for updates
- **Performance Improvements**: Optimization and performance enhancement records

Organized so that node operators can easily reference and apply updates.

### 4.3. Blockchain Node Issue Documentation

Organizes common problems and solutions encountered during node operation:

- **Common Errors**: Frequently occurring error messages and solutions
- **Synchronization Issues**: Synchronization failures, slow synchronization, fork occurrences, etc.
- **Performance Issues**: High CPU/memory usage, disk I/O bottlenecks
- **Network Problems**: Peer connection failures, port issues, firewall settings
- **Data Corruption**: Checksum errors, database recovery
- **Post-Update Issues**: Problems occurring after version updates
- **Hardware-Related**: Insufficient disk space, memory shortage

Each issue is systematically documented with symptoms, causes, and solutions.

### 4.4. Target Blockchains

**Starting with top 50 mainnets by CMC, gradually expanding**

The initial goal is to provide guides for the top 50 mainnet blockchains by market capitalization on CoinMarketCap (CMC). We plan to gradually expand the target blockchains to support more networks.

#### Priority Criteria
- **Market Capitalization**: Market cap ranking on CMC
- **Activity**: Network activity and transaction volume
- **Community**: Size of developer and user communities
- **Ecosystem**: Maturity of DApp and service ecosystems

#### Planned Blockchains (Examples)
- Bitcoin (BTC)
- Ethereum (ETH)
- Binance Smart Chain (BSC)
- Solana (SOL)
- Cardano (ADA)
- Polkadot (DOT)
- Avalanche (AVAX)
- Polygon (MATIC)
- Cosmos (ATOM)
- ... (Top 50)

For each blockchain, the following information is provided:
- Node installation guide (`/chains/[chain-name]/installation.md`)
- Configuration guide (`/chains/[chain-name]/configuration.md`)
- Update logs (`/chains/[chain-name]/updates/`)
- Issues and troubleshooting (`/chains/[chain-name]/troubleshooting.md`)

## Project Structure

```
blockchain-node-guides/
├── README.md
├── chains/
│   ├── bitcoin/
│   │   ├── installation.md
│   │   ├── configuration.md
│   │   ├── updates/
│   │   └── troubleshooting.md
│   ├── ethereum/
│   │   ├── installation.md
│   │   ├── configuration.md
│   │   ├── updates/
│   │   └── troubleshooting.md
│   └── ...
└── common/
    ├── hardware-requirements.md
    └── security-best-practices.md
```

## Contributing

This project welcomes community contributions:

1. Adding new blockchain guides
2. Improving and updating existing guides
3. Issue reporting and bug fixes
4. Documentation translation and improvements

## License

This project is distributed under the MIT License.

## Contact

If you have any questions or suggestions about the project, please open an issue.
