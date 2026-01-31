# Signature Move Authority System - Backend

Blockchain-based hierarchical signature authorization system using HKAS (Hierarchical Key Assignment Scheme) cryptography, Monad testnet, and Agno AI agents.

## 🏗️ Architecture

- **Backend:** Python + FastAPI + Socket.IO
- **Blockchain:** Monad Testnet (Solidity Smart Contracts)
- **Database:** PostgreSQL + Redis
- **AI Agents:** Agno SDK with GPT-4o-mini
- **Cryptography:** HKAS (CVP-IPS based)

## 🚀 Quick Start with Docker

### Prerequisites

- Docker & Docker Compose
- OpenAI API Key (for Agno agents)
- Monad Testnet Wallet Private Key (for admin operations)

### 1. Environment Setup

Create a `.env` file in the `backend/` directory:

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```env
OPENAI_API_KEY=sk-your-openai-api-key
ADMIN_WALLET_PRIVATE_KEY=your-monad-testnet-private-key
HKAS_ENCRYPTION_KEY=your-fernet-encryption-key
JWT_SECRET_KEY=your-jwt-secret-key
```

**Generate Fernet Key:**
```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 2. Start Services

```bash
docker-compose up
```

This will start:
- ✅ PostgreSQL database (port 5432)
- ✅ Redis cache (port 6379)
- ✅ FastAPI backend (port 8000)

### 3. Access the API

- **API Documentation:** http://localhost:8000/docs
- **Health Check:** http://localhost:8000/health
- **Socket.IO:** ws://localhost:8000/socket.io

### 4. Run Database Migrations

```bash
docker-compose exec backend alembic upgrade head
```

### 5. Seed Demo Data (Optional)

```bash
docker-compose exec backend python scripts/seed_demo_data.py
```

## 🛠️ Development Setup (Without Docker)

### 1. Install Dependencies

```bash
# Install uv (fast Python package manager)
pip install uv

# Install dependencies
uv pip install -r pyproject.toml
```

### 2. Setup Database

```bash
# Start PostgreSQL and Redis
docker-compose up postgres redis -d

# Run migrations
alembic upgrade head
```

### 3. Run Backend

```bash
uvicorn app.main:socket_app --reload
```

## 📁 Project Structure

```
backend/
├── app/
│   ├── main.py                 # FastAPI + Socket.IO app
│   ├── config.py               # Configuration settings
│   ├── api/
│   │   └── routes/             # API endpoints
│   ├── core/
│   │   ├── crypto/             # HKAS implementation
│   │   ├── blockchain/         # Web3 integration
│   │   └── agents/             # Agno AI agents
│   ├── models/                 # SQLAlchemy models
│   ├── services/               # Business logic
│   └── db/                     # Database utilities
├── alembic/                    # Database migrations
├── tests/                      # Unit & integration tests
├── docker-compose.yml          # Docker services
├── Dockerfile                  # Backend container
└── pyproject.toml              # Python dependencies
```

## 🔑 Key Features

### 1. HKAS Cryptography
- Hierarchical key assignment scheme
- CVP-IPS (Closest Vector Problem in Inner Product Space)
- Dynamic key updates (user/class insertion/deletion)

### 2. Authority Score System
- Each group has an authority score (CEO=100, CFO=80, etc.)
- Contracts require minimum total score
- Any combination meeting the threshold can approve

### 3. Blockchain Integration
- Monad Testnet smart contracts
- Real-time event listening (WebSocket)
- Multi-signature support

### 4. AI Agents (Agno)
- **Smart Router:** Analyzes contracts and suggests optimal routing
- **Compliance Checker:** Validates contracts against rules
- **Error Handler:** Manages blockchain transaction errors

### 5. Real-time Communication
- Socket.IO for live notifications
- Contract status updates
- Signature events

## 🧪 Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_hkas_math.py -v
```

## 📚 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login with credentials
- `POST /api/v1/auth/wallet-connect` - Connect MetaMask wallet

### Contracts
- `POST /api/v1/contracts` - Create new contract
- `GET /api/v1/contracts` - List contracts
- `GET /api/v1/contracts/{id}` - Get contract details
- `POST /api/v1/contracts/{id}/sign` - Sign contract

### Hierarchy
- `GET /api/v1/hierarchy/graph` - Get hierarchy visualization data
- `POST /api/v1/hierarchy/groups` - Create new group (admin)

### Admin
- `GET /api/v1/admin/contracts` - View all contracts
- `GET /api/v1/admin/blockchain/events` - Recent blockchain events

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql+asyncpg://...` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379/0` |
| `MONAD_RPC_URL` | Monad testnet RPC endpoint | `https://testnet-rpc.monad.xyz` |
| `MONAD_WSS_URL` | Monad testnet WebSocket endpoint | `wss://testnet-rpc.monad.xyz` |
| `ADMIN_WALLET_PRIVATE_KEY` | Admin wallet private key | - |
| `OPENAI_API_KEY` | OpenAI API key for Agno agents | - |
| `HKAS_ENCRYPTION_KEY` | Fernet key for encrypting shares | - |
| `JWT_SECRET_KEY` | JWT token secret | - |

## 🐳 Docker Commands

```bash
# Start all services
docker-compose up

# Start in detached mode
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Rebuild backend
docker-compose up --build backend

# Execute command in backend container
docker-compose exec backend <command>
```

## 📖 Documentation

- [Implementation Plan](../docs/implementation_plan.md)
- [HKAS Implementation](../docs/HKAS_IMPLEMENTATION.md)
- [Smart Contracts](../docs/SMART_CONTRACTS.md)
- [API Reference](http://localhost:8000/docs)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `pytest`
4. Submit a pull request

## 📄 License

MIT License
