# Agent Store

AI Agent prompt paylaşım platformu. Promptları keşfet, pixel-art karakter üret, Monad testnet cüzdanınla giriş yap.

---

## İçindekiler

- [Gereksinimler](#gereksinimler)
- [Yerel Geliştirme (Docker)](#yerel-geliştirme-docker)
- [Ortam Değişkenleri](#ortam-değişkenleri)
- [Sadece Backend](#sadece-backend)
- [Sadece Frontend](#sadece-frontend)
- [Smart Contracts](#smart-contracts)
- [Production Deploy](#production-deploy)
- [API Endpointleri](#api-endpointleri)
- [Sorun Giderme](#sorun-giderme)

---

## Gereksinimler

| Araç | Minimum | Notlar |
|------|---------|--------|
| Docker Desktop | 24+ | Tüm servisleri çalıştırmak için |
| Git | herhangi | |
| Node.js | 18+ | Yalnızca smart contract geliştirme için |
| Flutter SDK | 3.x stable | Yalnızca yerel frontend geliştirme için |

> Go ve PostgreSQL kurmanıza gerek yok — Docker her şeyi halleder.

---

## Yerel Geliştirme (Docker)

### 1. Repoyu klonla

```bash
git clone <repo-url>
cd Agent_Store_Full
```

### 2. `.env` dosyasını oluştur

```bash
cp .env.example .env
```

`.env` içindeki asgari zorunlu değerler:

```env
JWT_SECRET=herhangi_bir_gizli_deger
CLAUDE_API_KEY=sk-ant-...        # opsiyonel, yoksa keyword matching devreye girer
```

Diğer tüm değişkenlerin varsayılanları zaten çalışır durumdadır.

### 3. Servisleri başlat

```bash
docker compose up -d
```

İlk çalıştırmada image'lar build edilir (~2–5 dk). Sonraki başlatmalar hızlıdır.

### 4. Servislerin hazır olmasını bekle

```bash
docker compose ps
```

Beklenen çıktı:

```
agent_store_db        ... Up (healthy)   0.0.0.0:5432->5432/tcp
agent_store_backend   ... Up             0.0.0.0:8080->8080/tcp
agent_store_frontend  ... Up             0.0.0.0:80->80/tcp
```

### 5. Aç

| Adres | Ne açılır |
|-------|-----------|
| http://localhost | Flutter frontend |
| http://localhost:8080/health | Backend sağlık kontrolü |
| http://localhost:8080/api/v1/agents | Agent listesi (JSON) |

### Servisleri durdur

```bash
docker compose down          # container'ları durdur (veri korunur)
docker compose down -v       # container + veritabanı verisi sil
```

### Logları izle

```bash
docker compose logs -f backend    # backend logları (canlı)
docker compose logs -f frontend   # frontend logları
docker compose logs -f            # tüm servisler
```

### Kodu değiştirdikten sonra yeniden build

```bash
# Yalnızca backend değiştiyse:
docker compose build backend && docker compose up -d backend

# Yalnızca frontend değiştiyse:
docker compose build frontend && docker compose up -d frontend

# Her ikisi de değiştiyse:
docker compose build && docker compose up -d
```

---

## Ortam Değişkenleri

`.env` dosyasına koyulur (kök dizin). Varsayılanlar köşeli parantez içinde.

| Değişken | Açıklama | Varsayılan |
|----------|----------|------------|
| `PORT` | Backend port | `8080` |
| `POSTGRES_HOST` | PostgreSQL host | `localhost` |
| `POSTGRES_PORT` | PostgreSQL port | `5432` |
| `POSTGRES_USER` | Veritabanı kullanıcısı | `agent_user` |
| `POSTGRES_PASSWORD` | Veritabanı şifresi | `agent_pass` |
| `POSTGRES_DB` | Veritabanı adı | `agent_store` |
| `JWT_SECRET` | JWT imzalama anahtarı | `dev_secret_change_me` |
| `CLAUDE_API_KEY` | Anthropic API anahtarı | _(boş — keyword fallback)_ |
| `ALLOWED_ORIGINS` | CORS izinli originler (virgülle) | `http://localhost:80,...` |
| `MONAD_RPC_URL` | Monad testnet RPC | `https://testnet-rpc.monad.xyz` |
| `CREDITS_CONTRACT_ADDRESS` | Deploy edilmiş kontrat adresi | _(boş)_ |
| `API_BASE_URL` | Frontend'in backend'e bağlandığı URL | `http://localhost:8080` |

> Production için `.env.production.example` dosyasına bakın.

---

## Sadece Backend

Go kurulu değilse Docker ile derle ve test et:

```bash
# Derleme testi
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "C:/flutter_projeler/Agent_Store_Full/backend:/app" \
  -w //app golang:1.22-alpine \
  go build -o /tmp/s ./cmd/server

# Sadece backend + postgres başlat
docker compose up -d postgres backend
```

---

## Sadece Frontend

Flutter SDK kuruluysa Docker olmadan çalıştır:

```bash
cd agent_store

# Bağımlılıkları kur
flutter pub get

# Geliştirme sunucusu (localhost:8080'de backend çalışıyor olmalı)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080

# Release build
flutter build web --release --dart-define=API_BASE_URL=http://localhost:8080
# Çıktı: agent_store/build/web/
```

---

## Smart Contracts

### Kurulum

```bash
cd contracts
npm install
```

### Derleme ve Test

```bash
npm run compile      # Solidity derle
npm run test         # Mocha/Chai testleri çalıştır (7 test)
```

### Yerel ağa deploy

```bash
# Terminal 1 — yerel Hardhat node başlat
npm run node

# Terminal 2 — deploy
npm run deploy:local
```

### Monad Testnet'e deploy

`contracts/.env` dosyası oluştur:

```env
DEPLOYER_PRIVATE_KEY=0x<cüzdan-private-key>
MONAD_RPC_URL=https://testnet-rpc.monad.xyz
```

```bash
npm run deploy
```

Deploy sonrası çıktıdan `CREDITS_CONTRACT_ADDRESS` değerini alıp kök `.env`'e ekle.

> Monad testnet faucet: https://faucet.monad.xyz (test MON için)

---

## Production Deploy

### Backend → Railway

1. [railway.app](https://railway.app) → **New Project** → **Deploy from GitHub repo**
2. **PostgreSQL** plugin ekle (bağlantı bilgileri otomatik inject edilir)
3. **Variables** sekmesine `.env.production.example` içindeki değerleri gir
4. Railway, `railway.toml`'u otomatik okur ve Dockerfile ile build eder

### Frontend → Vercel

1. [vercel.com](https://vercel.com) → **New Project** → GitHub reposu seç
2. **Framework Preset**: Other
3. **Root Directory**: `agent_store`
4. **Build Command**: `flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL`
5. **Output Directory**: `build/web`
6. **Environment Variables**'a `API_BASE_URL=https://<railway-url>.up.railway.app` ekle

### GitHub Actions ile otomatik CI/CD

`main` branch'e her push'ta otomatik deploy tetiklenir. Bunun için repo ayarlarında şu secrets/variables gereklidir:

**Secrets:**

| İsim | Nereden alınır |
|------|----------------|
| `RAILWAY_TOKEN` | Railway → Account Settings → Tokens |
| `VERCEL_TOKEN` | Vercel → Account Settings → Tokens |
| `VERCEL_ORG_ID` | Vercel → Team/Account Settings |
| `VERCEL_PROJECT_ID` | Vercel → Project Settings |

**Variables:**

| İsim | Değer |
|------|-------|
| `API_BASE_URL` | `https://<uygulama>.up.railway.app` |

---

## API Endpointleri

Base URL: `http://localhost:8080` (geliştirme)

| Method | Path | Auth | Açıklama |
|--------|------|------|----------|
| GET | `/health` | — | Sağlık kontrolü |
| GET | `/api/v1/auth/nonce/:wallet` | — | Cüzdan için nonce üret |
| POST | `/api/v1/auth/verify` | — | İmzayı doğrula → JWT döndür |
| GET | `/api/v1/agents` | — | Agent listesi (`?category=&search=&page=&limit=`) |
| GET | `/api/v1/agents/:id` | — | Agent detayı |
| POST | `/api/v1/agents` | JWT | Yeni agent oluştur |
| GET | `/api/v1/user/library` | JWT | Kayıtlı agentlar |
| POST | `/api/v1/user/library/:id` | JWT | Kütüphaneye ekle |
| DELETE | `/api/v1/user/library/:id` | JWT | Kütüphaneden çıkar |
| GET | `/api/v1/user/credits` | JWT | Kredi sorgula |

JWT, `Authorization: Bearer <token>` header'ı ile gönderilir.

---

## Sorun Giderme

### `docker compose up` sonrası backend hemen kapanıyor

```bash
docker compose logs backend
```

Genellikle postgres henüz hazır değildir. `docker compose up -d` tekrar deneyin — `depends_on: condition: service_healthy` bunu otomatik bekler.

### Git Bash'te Docker path hatası

`//` veya `MSYS_NO_PATHCONV=1` kullanın:

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v "C:/path:/app" -w //app ...
```

### MetaMask bağlanmıyor

- MetaMask'ın tarayıcıda kurulu olduğundan emin olun
- Network olarak **Monad Testnet** eklenmiş olmalı: RPC `https://testnet-rpc.monad.xyz`, Chain ID `10143`

### Claude AI çalışmıyor, karakter tipi hep "wizard"

`.env`'de `CLAUDE_API_KEY` boş bırakılmışsa keyword matching devreye girer. Bu normaldir. API key eklenince AI analizi aktif olur.

### Frontend değişiklikleri görünmüyor

```bash
docker compose build frontend && docker compose up -d frontend
```

Tarayıcıda hard refresh yapın (Ctrl+Shift+R).