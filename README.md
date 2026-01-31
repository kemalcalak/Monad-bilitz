# Signature Move Authority System (Monad-bilitz)

A blockchain-based hierarchical signature authorization system leveraging HKAS (Hierarchical Key Assignment Scheme), the Monad Testnet, and Agno AI agents to provide secure, dynamic, and intelligent contract management.

## 🌟 Project Overview

This project implements a secure document signing and authority management system where signature power is determined by a hierarchical structure (e.g., Company Hierarchy: CEO > CTO > Manager). It uses:
- **HKAS Cryptography** to enforce hierarchy-based security.
- **Monad Testnet** for transparent and immutable audit logs of all authority changes and signatures.
- **Agno AI Agents** to intelligently route contracts and ensure compliance.
- **Flutter Mobile App** for real-time management and signing on the go.

---

## 🏗️ Architecture

The system is divided into three main components:

### 1. Backend (`/backend`)
The core logic of the system, built with **Python (FastAPI)**. It acts as the bridge between the mobile app, the blockchain, and the AI agents.
- **Framework:** FastAPI with Uvicorn.
- **Database:** PostgreSQL (Data persistence) & Redis (Caching/Queues).
- **AI Integration:** Uses **Agno SDK** to power intelligent agents:
  - `Smart Router`: Analyzes contracts to determine the optimal signing path.
  - `Compliance Checker`: Validates contracts against regulatory rules.
  - `Error Handler`: Manages blockchain transaction failures.
- **Real-time:** Socket.IO server for instant updates to the mobile client.
- **Cryptography:** Implements the HKAS (Closest Vector Problem in Inner Product Space) algorithm.

### 2. Smart Contracts (`/contracts`)
Solidity smart contracts deployed on the **Monad Testnet**.
- **Framework:** Hardhat.
- **Key Contracts:**
  - `HierarchyManager.sol`: Manages organizational groups, authority scores, and user assignments. It enforces the rule that only users with sufficient authority scores (defined by their group) can perform certain actions.
  - `SignatureAuthority.sol`: Handles the logic for collecting and validating multi-signature requests on-chain.

### 3. Mobile App (`/flutter_monad`)
A cross-platform mobile application built with **Flutter**.
- **Architecture:** Clean Architecture (Data, Domain, Presentation layers).
- **State Management:** BLoC (Business Logic Component).
- **Features:**
  - **Dashboard:** Visualizes hierarchy and current tasks using Syncfusion charts.
  - **Signature Flow:** Secure signing interface with cryptographic proof generation.
  - **Real-time:** Listens to Socket.IO events for new contract requests.

---

## 📂 Project Structure

### Backend (`/backend`)
```bash
backend/
├── app/
│   ├── api/            # REST API Routes (Auth, Contracts, Hierarchy)
│   ├── core/           # Core logic (Agents, Blockchain Client, HKAS Crypto)
│   ├── models/         # SQLAlchemy Database Models
│   ├── services/       # Business Logic Layer
│   └── main.py         # Application Entrypoint
├── alembic/            # Database Migrations
└── tests/              # Pytest Unit & Integration Tests
```

### Smart Contracts (`/contracts`)
```bash
contracts/
├── contracts/
│   ├── HierarchyManager.sol    # Hierarchy & Score Logic
│   └── SignatureAuthority.sol  # Signature Verification
├── scripts/            # Deployment Scripts
└── hardhat.config.js   # Network Configuration
```

### Mobile App (`/flutter_monad`)
```bash
flutter_monad/
├── lib/
│   ├── core/           # Config, Constants, Theme
│   ├── data/           # Repositories, API Services, DTOs
│   ├── domain/         # Entities & UseCases (Business Rules)
│   └── presentation/   # UI Pages, BLoCs, Widgets
└── pubspec.yaml        # Dependencies
```

---

## 🚀 Getting Started

### Prerequisites
- Docker & Docker Compose
- Node.js & NPM (for Hardhat)
- Flutter SDK (for Mobile)
- Python 3.11+
- Monad Testnet Wallet (Private Key)
- OpenAI API Key (for Agno Agents)

### 1. Backend Setup
The backend can be easily started using Docker.

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Create environment file:
   ```bash
   cp .env.example .env
   # Update .env with your KEYS (OpenAI, Monad Private Key, etc.)
   ```
3. Start services:
   ```bash
   docker-compose up -d
   ```
4. Run migrations:
   ```bash
   docker-compose exec backend alembic upgrade head
   ```

### 2. Smart Contracts Setup
Deploy the contracts to the Monad Testnet.

1. Navigate to the contracts directory:
   ```bash
   cd contracts
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Deploy:
   ```bash
   npx hardhat run scripts/deploy.js --network monad
   # Copy the deployed contract addresses to your backend .env file
   ```

### 3. Mobile App Setup
Run the Flutter application.

1. Navigate to the mobile directory:
   ```bash
   cd flutter_monad
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## 👥 Contributors

*   [Ali Kemal Çalak](https://github.com/kemalcalak)
*   [Furkan Berk](https://github.com/Nighctap)
*   [Furkan Eren Akıncı](https://github.com/furkanerenakinci)
