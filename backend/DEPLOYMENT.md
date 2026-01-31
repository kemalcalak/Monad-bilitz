# Deployment Guide

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for smart contracts)
- Python 3.11+
- Monad Testnet wallet with MON tokens

---

## 📋 Step 1: Environment Configuration

### Backend Environment

Create `backend/.env` file:

```bash
# Database
DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/monad_bilitz

# Redis
REDIS_URL=redis://redis:6379/0

# JWT Authentication
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
JWT_ALGORITHM=HS256
JWT_EXPIRATION_DAYS=7

# Monad Testnet
MONAD_RPC_URL=https://testnet-rpc.monad.xyz
MONAD_WSS_URL=wss://testnet-rpc.monad.xyz
MONAD_CHAIN_ID=10143

# Admin Wallet (for contract deployment)
ADMIN_WALLET_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE

# OpenAI (for Agno AI Agents)
OPENAI_API_KEY=sk-your-openai-api-key

# Socket.IO
SOCKETIO_CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]

# HKAS Cryptography
HKAS_ENCRYPTION_KEY=generate-with-fernet-key-gen
PRIME_FIELD_BITS=256
DEFAULT_SECURITY_LEVEL=128
DEFAULT_BETA=2

# Smart Contract Addresses (deploy contracts first, then add here)
HIERARCHY_MANAGER_ADDRESS=0x...
SIGNATURE_AUTHORITY_ADDRESS=0x...
```

### Generate HKAS Encryption Key

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

---

## 📦 Step 2: Smart Contract Deployment

### Install Dependencies

```bash
cd contracts
pnpm install
```

### Deploy to Monad Testnet

```bash
# Make sure you have MON tokens in your wallet
pnpm hardhat run scripts/deploy.js --network monadTestnet
```

**Output will show:**
```
HierarchyManager deployed to: 0x1234...
SignatureAuthority deployed to: 0x5678...
```

**Copy these addresses to `backend/.env`:**
```bash
HIERARCHY_MANAGER_ADDRESS=0x1234...
SIGNATURE_AUTHORITY_ADDRESS=0x5678...
```

---

## 🐳 Step 3: Docker Deployment

### Development

```bash
cd backend

# Start all services
make up

# View logs
make logs

# Run migrations (after containers are up)
make migrate

# Seed demo data
make seed
```

### Production

Update `docker-compose.yml` for production:

```yaml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-change-in-production}
      POSTGRES_DB: ${POSTGRES_DB:-monad_bilitz}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: always
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  backend:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=postgresql+asyncpg://${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD:-change-in-production}@db:5432/${POSTGRES_DB:-monad_bilitz}
      - REDIS_URL=redis://redis:6379/0
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "8000:8000"
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:

networks:
  default:
    name: monad_network
```

---

## 🗄️ Step 4: Database Setup

### Run Migrations

```bash
# Inside backend container or locally
alembic upgrade head
```

### Seed Demo Data

```bash
python scripts/seed_demo_data.py
```

**Demo Users:**
- `ceo_user` / `password123` - CEO (score: 100)
- `cfo_user` / `password123` - CFO (score: 80)
- `cto_user` / `password123` - CTO (score: 80)
- `dept_user` / `password123` - DEPT_HEAD (score: 50)
- `manager_user` / `password123` - MANAGER (score: 30)
- `employee_user` / `password123` - EMPLOYEE (score: 10)

---

## 🔍 Step 5: Verification

### Check Services

```bash
# Check backend health
curl http://localhost:8000/health

# Check API docs
open http://localhost:8000/docs

# Check database
docker exec -it monad-bilitz-db-1 psql -U postgres -d monad_bilitz -c "\dt"
```

### Test Authentication

```bash
# Register user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=password123"
```

### Test Contract Creation

```bash
# Get token from login response
TOKEN="your-jwt-token"

# Create contract
curl -X POST http://localhost:8000/api/v1/contracts/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Contract",
    "content": "This is a test contract",
    "contract_type": "general",
    "amount": 5000,
    "urgency": "normal"
  }'
```

---

## 🔧 Troubleshooting

### Database Connection Issues

```bash
# Check database logs
docker logs monad-bilitz-db-1

# Restart database
docker restart monad-bilitz-db-1
```

### Blockchain Connection Issues

```bash
# Test Monad RPC
curl -X POST https://testnet-rpc.monad.xyz \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Migration Issues

```bash
# Check current migration version
alembic current

# Rollback one version
alembic downgrade -1

# Re-apply
alembic upgrade head
```

---

## 📊 Monitoring

### View Logs

```bash
# All services
make logs

# Backend only
docker logs -f monad-bilitz-backend-1

# Database only
docker logs -f monad-bilitz-db-1
```

### Database Queries

```bash
# Connect to database
make db-shell

# Check users
SELECT username, email, group_id FROM users;

# Check contracts
SELECT contract_id, title, status, required_score, current_score FROM contracts;

# Check groups
SELECT group_name, display_name, authority_score FROM groups;
```

---

## 🔐 Security Checklist

- [ ] Change `JWT_SECRET_KEY` to a strong random value
- [ ] Change database password in production
- [ ] Restrict CORS origins to your frontend domain
- [ ] Never commit `.env` file to git
- [ ] Keep `ADMIN_WALLET_PRIVATE_KEY` secure
- [ ] Use environment variables for all secrets
- [ ] Enable HTTPS in production
- [ ] Set up firewall rules
- [ ] Regular database backups

---

## 📚 Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Monad Testnet](https://docs.monad.xyz/)
- [Agno Documentation](https://docs.agno.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Alembic Migrations](https://alembic.sqlalchemy.org/)

---

## 🆘 Support

For issues or questions:
1. Check logs: `make logs`
2. Review environment variables
3. Verify smart contract deployment
4. Check database migrations
5. Test blockchain connectivity
