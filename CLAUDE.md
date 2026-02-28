# Agent Store — CLAUDE.md
> Team Leader tarafından tutulur. Her sprint sonrası güncellenir.

## Proje Özeti
AI Agent prompt paylaşım platformu. Kullanıcılar agent promptlarını keşfeder, kütüphanesine ekler, kendi promptunu yükler. Her prompt analiz edilerek benzersiz pixel-art karakter üretilir. Giriş Monad testnet cüzdanı ile yapılır; kredi sistemi on-chain yönetilir.

---

## Teknoloji Yığını
| Katman | Teknoloji |
|---|---|
| Frontend | Flutter Web (Dart) |
| Backend | Go 1.22 + Gin + GORM |
| Veritabanı | PostgreSQL 16 |
| Blockchain | Monad Testnet (EVM) · Solidity 0.8.24 |
| Konteyner | Docker + docker-compose |
| Deploy | Vercel (Flutter static) + Railway/Fly.io (Go API) |
| AI | Claude API (prompt analiz + karakter tipi belirleme) |

---

## Mimari
```
Agent_Store_Full/
├── agent_store/          # Flutter Web frontend
│   ├── lib/
│   │   ├── app/          # Router, Theme
│   │   ├── features/     # store | agent_detail | library | create_agent | wallet | character
│   │   ├── shared/       # models | services | widgets
│   │   └── core/         # constants | utils
│   ├── Dockerfile
│   └── nginx.conf
├── backend/              # Go REST API
│   ├── cmd/server/
│   ├── internal/
│   │   ├── api/          # handlers | middleware | router
│   │   ├── models/
│   │   ├── services/     # agent | auth | ai | character
│   │   ├── database/
│   │   └── config/
│   └── Dockerfile
├── contracts/            # Solidity (Hardhat)
│   ├── contracts/        # AgentStoreCredits.sol | AgentRegistry.sol
│   └── scripts/          # deploy.js
├── docker-compose.yml
└── CLAUDE.md             # ← bu dosya
```

---

## API Endpointleri (Go)
| Method | Path | Açıklama |
|---|---|---|
| POST | /api/v1/auth/nonce | Cüzdan için nonce üret |
| POST | /api/v1/auth/verify | İmzayı doğrula → JWT döndür |
| GET | /api/v1/agents | Agent listesi (filtre + sayfalama) |
| POST | /api/v1/agents | Yeni agent oluştur |
| GET | /api/v1/agents/:id | Agent detayı |
| POST | /api/v1/agents/:id/generate | Karakter üret (Claude AI) |
| GET | /api/v1/user/library | Kütüphane |
| POST | /api/v1/user/library/:id | Kütüphaneye ekle |
| DELETE | /api/v1/user/library/:id | Kütüphaneden çıkar |
| GET | /api/v1/user/credits | Kredi sorgula |

---

## Veritabanı Şeması
```
users           : wallet_address (PK), nonce, credits, created_at
agents          : id, title, description, prompt, category, creator_wallet,
                  character_type, character_data (JSON), rarity, tags, created_at
library_entries : user_wallet, agent_id, saved_at
```

---

## Karakter Sistemi (Gamification)
Prompt → Claude API analiz → character_type → Flutter CustomPainter pixel-art

| Karakter | Prompt Tipi | Renk Paleti |
|---|---|---|
| Wizard | backend / kod | Mor, Gece mavisi |
| Strategist | planlayıcı / PM | Kırmızı, Altın |
| Oracle | veri / analitik | Sarı, Turuncu |
| Guardian | güvenlik / infra | Gri, Mavi |
| Artisan | frontend / tasarım | Pembe, Turkuaz |
| Bard | yaratıcı / yazarlık | Yeşil, Limon |
| Scholar | araştırma / eğitim | Bej, Kahve |
| Merchant | iş / pazarlama | Altın, Lacivert |

Nadir dereceler: Common → Uncommon → Rare → Epic → Legendary

---

## Blockchain (Monad Testnet)
- **AgentStoreCredits.sol**: ERC-20 benzeri on-chain kredi
- **AgentRegistry.sol**: Agent sahipliği kaydı
- Giriş akışı: `eth_requestAccounts` → `personal_sign(nonce)` → backend doğrula → JWT
- RPC: `https://testnet-rpc.monad.xyz` · ChainID: `10143`

---

## Docker Servisleri
```yaml
services:
  postgres   → port 5432
  backend    → port 8080
  frontend   → port 80  (nginx static)
  contracts  → migration/deploy (one-shot)
```

---

## Team Agents
| Agent | Sorumluluk |
|---|---|
| Team Leader (Claude ana) | Koordinasyon, entegrasyon, CLAUDE.md |
| Backend | Go API, veritabanı, servisler |
| Frontend | Flutter UI, routing, state |
| Gamification Master | Pixel-art karakterler, rarity sistemi |
| Blockchain Expert | Solidity kontrat, Web3 auth, Monad deploy |

---

## Dosya Haritası (Team Leader tarafından oluşturuldu)

### Backend (Go) — 14 dosya ✅
| Dosya | Açıklama |
|---|---|
| `cmd/server/main.go` | Giriş noktası, config + DB + router başlatır |
| `config/config.go` | Env değişkenlerinden yapılandırma yükler |
| `internal/database/db.go` | GORM bağlantısı + AutoMigrate |
| `internal/models/user.go` | User modeli (wallet_address PK, credits) |
| `internal/models/agent.go` | Agent + LibraryEntry modelleri |
| `internal/services/auth_service.go` | Nonce üret, imza doğrula, JWT |
| `internal/services/agent_service.go` | Agent CRUD, kütüphane, kredi |
| `internal/services/character_service.go` | Prompt analiz → karakter tipi + nadir derece |
| `internal/api/router.go` | Gin router + CORS kurulumu |
| `internal/api/handlers/auth_handler.go` | GET /auth/nonce, POST /auth/verify |
| `internal/api/handlers/agent_handler.go` | CRUD + library endpoints |
| `internal/api/middleware/auth.go` | JWT doğrulama middleware |
| `Dockerfile` | Multi-stage Go build |

### Frontend (Flutter Web) — 17 dosya ✅
| Dosya | Açıklama |
|---|---|
| `lib/main.dart` | MaterialApp.router giriş noktası |
| `lib/app/theme.dart` | Koyu tema (indigo + dark bg) |
| `lib/app/router.dart` | GoRouter + AppShell sidebar |
| `lib/core/constants/api_constants.dart` | API URL sabitleri |
| `lib/features/character/character_types.dart` | CharacterType + CharacterRarity enum |
| `lib/features/character/character_data.dart` | 8 karakter × 16×16 pixel matrix |
| `lib/features/character/pixel_art_painter.dart` | CustomPainter + glow + float animasyon |
| `lib/shared/widgets/pixel_character_widget.dart` | Karakter widget (frame + stats + badge) |
| `lib/shared/models/agent_model.dart` | AgentModel.fromJson |
| `lib/shared/services/api_service.dart` | HTTP istemcisi (auth, agents, library) |
| `lib/shared/services/wallet_service.dart` | MetaMask köprüsü (JS interop) |
| `lib/features/store/screens/store_screen.dart` | Agent grid, arama, filtre |
| `lib/features/store/widgets/agent_card.dart` | Karakter + meta kart |
| `lib/features/agent_detail/screens/` | Detay + prompt kopyala + kütüphane toggle |
| `lib/features/library/screens/` | Kayıtlı agentlar grid |
| `lib/features/create_agent/screens/` | Form + canlı karakter önizleme |
| `lib/features/wallet/screens/` | MetaMask bağla / kredi görüntüle |
| `Dockerfile + nginx.conf` | Flutter web build + nginx SPA |

### Blockchain (Solidity) — 6 dosya ✅
| Dosya | Açıklama |
|---|---|
| `contracts/AgentStoreCredits.sol` | ERC-20 benzeri kredi sistemi |
| `contracts/AgentRegistry.sol` | Agent sahipliği + içerik hash kaydı |
| `hardhat.config.js` | Monad testnet + localhost ağ konfigü |
| `package.json` | Hardhat + OpenZeppelin bağımlılıkları |
| `scripts/deploy.js` | Deploy + deployments.json kaydı |
| `test/AgentStoreCredits.test.js` | Mocha/Chai birim testleri (7 test) |

## Sprint Notları
- [x] v0.1 — Proje iskeleti + Docker + CLAUDE.md (Team Leader)
- [x] v0.2 — Go API: auth, agent CRUD, character service (Backend)
- [x] v0.3 — Flutter UI: store, detail, library, create, wallet (Frontend)
- [x] v0.4 — 8 pixel-art karakter, rarity sistemi, animasyon (Gamification Master)
- [x] v0.5 — Solidity kontratlar, Monad testnet deploy scripti (Blockchain Expert)
- [x] v0.6 — flutter pub get + go mod tidy (go.sum 132 satır, flutter bağımlılıkları ok)
- [x] v0.7 — Web3 JS interop: index.html MetaMask köprüsü + dart:js_interop wallet_service
- [x] v1.0 — docker-compose up: 3 servis UP (postgres healthy, backend :8080, frontend :80) ✅
- [x] v1.1 — Claude AI entegrasyonu + keyword fallback (Backend)
- [x] v1.2 — Railway + Vercel deploy, GitHub Actions CI/CD (Team Leader)
- [x] v1.3 — E2E bug düzeltme (Backend + Frontend)
- [x] v2.0 — Gemini Flash analiz + Gemini Imagen karakter üretimi (Gamification Master + Backend)
- [x] **v2.1 — Replicate pixel-art-xl entegrasyonu** (Backend) ✅ 0 hata
- [x] **v2.2 — Trending + Category sidebar + Store UX** (Frontend) ✅ 0 hata
- [x] **v2.3 — Mini chat + Radar chart + Fork butonu** (Frontend + Backend) ✅ 0 hata
- [x] **v2.4 — Kullanıcı Profili ekranı** (Frontend + Backend) ✅ 0 hata
- [x] **v2.5 — Blockchain Credits + Leaderboard** (Backend + Frontend) → Blok 6 + 8 ✅
- [ ] **v2.6 — Docker rebuild + E2E test** (Team Leader) → SPRINT_V2_TRACKER.md #Blok7

## Sprint Takip Dosyaları
- `SPRINT_V2.md` — Detaylı plan ve teknik kararlar
- `SPRINT_V2_TRACKER.md` — Task bazlı ilerleme takibi (Team Leader günceller)