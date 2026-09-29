# LogiFlow — Production-Ready Enterprise Backend (FastAPI, SQLAlchemy 2.0 Async, PostgreSQL/SQLite, WebSockets, Redis)

## 📌 Xulosa (Executive Summary)

LogiFlow Flutter mobil ilovasi uchun to'liq **production-ready backend arxitekturasi** yaratildi. Flutter frontend kodi va dizayni o'zgartirilmasdan, mavjud barcha 15 ta modul (`auth`, `shipments`, `bids`, `wallet_escrow`, `tracking`, `chat`, `calls`, `disputes`, `documents`, `fleet`, `notifications`, `pod`, `sos`, `settings`, `admin`) bilan to'liq 100% integratsiyaga tayyor holatga keltirildi.

---

## 🏛️ Arxitektura & Texnologiyalar

| Komponent | Texnologiya | Tavsifi |
| :--- | :--- | :--- |
| **Til & Runtime** | Python 3.13.14 | Zamonaviy tezkor asinxron runtime |
| **Web Framework** | FastAPI + Pydantic v2 | Yuqori unumdorlik, avtomatik OpenAPI/Swagger hujjatlari |
| **ORM & DB** | SQLAlchemy 2.0 Async + asyncpg / aiosqlite | Asinxron connection pooling, `selectin` eager loading |
| **Xavfsizlik** | Bcrypt + JWT (Access + Refresh Token Rotation) + RBAC | RBAC ruxsatlar nazorati, ko'p qurilmali sessiyalar |
| **Escrow & Wallet** | Double-entry ledger (Ikki tomonlama buxgalteriya balansi) | `SELECT FOR UPDATE` qulflash, `Idempotency-Key` takroriy to'lovdan himoya |
| **Real-time** | WebSockets (Pub-Sub Connection Manager) | GPS Telemetriya, jonli Chat, status yangilanishlari |
| **To'lov Gateway** | Payme & Click Webhook Adapter | JSON-RPC 2.0 va tranzaksiya tasdiqlash xizmati |
| **Test Suite** | PyTest + pytest-asyncio + httpx | Avtomatlashtirilgan asinxron testlar |
| **Deploy** | Docker + Docker Compose | PostgreSQL 16 + Redis + FastAPI servislar to'plami |

---

## 🗂️ Loyiha Strukturasi (`backend/`)

```
backend/
├── app/
│   ├── config/
│   │   └── settings.py          # Pydantic BaseSettings konfiguratsiyasi (.env dan o'qish)
│   ├── core/
│   │   ├── enums.py             # Barcha domen enumlari (LoadStatus, UserRole, etc.)
│   │   ├── exceptions.py        # Custom Domain Exceptions & Error Codes
│   │   └── security.py          # Bcrypt hashing, JWT access/refresh token generator
│   ├── database/
│   │   ├── base.py              # DeclarativeBase va TimestampMixin
│   │   ├── session.py           # Async engine & sessionmaker (Postgres/SQLite)
│   │   └── seed.py              # Mock ma'lumotlarni to'ldiruvchi demo seeder
│   ├── models/                  # 16 ta SQLAlchemy 2.0 Async modeli
│   │   ├── user.py              # User, UserSession, LoginHistory, UserOTP
│   │   ├── shipment.py          # Shipment, ShipmentStatusHistory (12-bosqich)
│   │   ├── bid.py               # Bid, NegotiationStep
│   │   ├── wallet.py            # Wallet, EscrowLock, LedgerTransaction
│   │   ├── tracking.py          # TrackingData, TelemetryLog
│   │   ├── chat.py              # ChatChannel, ChatMessage
│   │   ├── call.py              # CallSession, CallLog
│   │   ├── dispute.py           # Dispute, DisputeTimeline
│   │   ├── document.py          # Document (Document Vault)
│   │   ├── vehicle.py           # Vehicle (MAN, Scania, Volvo)
│   │   ├── driver.py            # DriverProfile
│   │   ├── notification.py      # Notification, DeviceToken
│   │   ├── sos.py               # SosProvider, SosRequest
│   │   └── audit.py             # AuditLog
│   ├── schemas/                 # 18 ta Pydantic v2 validation va serialization schemalari
│   ├── repositories/            # Asinxron repository pattern (CRUD + optimallashtirilgan filterlar)
│   ├── services/                # Biznes mantiq qatlami (Auth, Escrow, Shipment, AI Matcher, etc.)
│   ├── websocket/
│   │   └── connection_manager.py # Real-time pub-sub broadcasting xizmati
│   ├── dependencies/            # FastAPI Depends (Auth, DB, Current User)
│   ├── permissions/             # RBAC Role Checker
│   ├── api/v1/                  # REST API v1 marshrutlari (16 ta router)
│   └── main.py                  # Asosiy FastAPI Factory, CORS, Middlewares
├── tests/                       # Pytest asinxron test to'plami
├── Dockerfile                   # Production konteyner
├── docker-compose.yml           # PostgreSQL, Redis, FastAPI servislar
├── requirements.txt             # Barcha Python kutubxonalar
├── .env.example                 # Standart konfiguratsiya andozasi
└── .env                         # Ishga tushirish muhiti parametrlari
```

---

## 🚀 Qanday Ishga Tushirish Mumkin?

### 1. Mahalliy muhitda (Local Dev):
```powershell
# Backend papkasiga o'tish
cd backend

# Virtual muhit yaratish va kutubxonalarni o'rnatish
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Serverni ishga tushirish (Avtomatik DB jadvallar yaratiladi va ma'lumotlar seed qilinadi)
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Docker Compose yordamida (Production-ready):
```powershell
docker-compose up --build -d
```

### 3. Swagger & Hujjatlar:
Server ishga tushgach quyidagi havolalar orqali barcha API'larni interaktiv sinab ko'rish mumkin:
- **Interactive Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc Technical Specification**: [http://localhost:8000/redoc](http://localhost:8000/redoc)
- **Healthcheck**: [http://localhost:8000/health](http://localhost:8000/health)

---

## 🔑 Demo Foydalanuvchilar (Baza avtomatik to'ldirilgan)

| Rol | Email / Telefon | Parol | Balans |
| :--- | :--- | :--- | :--- |
| **Shipper (Yuk egasi)** | `anvar@agrotrade.uz` / `+998909991122` | `password123` | 42,500,000 UZS |
| **Carrier (Kompaniya)** | `dilshod@translog.uz` / `+998934567890` | `password123` | 28,900,000 UZS |
| **Driver (Haydovchi)** | `rustam.driver@logiflow.uz` / `+998977654321` | `password123` | 9,800,000 UZS |
| **Admin (Tizim boshqaruvchisi)** | `admin@logiflow.uz` / `+998712000000` | `password123` | 150,000,000 UZS |
