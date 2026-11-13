# 🚀 LogiFlow Production Deployment Guide (DEPLOY.md)

Ushbu qo'llanma **LogiFlow** yuk tashish ekotizimini (FastAPI backend, PostgreSQL 16, Redis 7, Coturn WebRTC TURN/STUN, Flutter Web frontend va Caddy avtomatik SSL) to'liq **production server (VPS / Dedicated Server)** muhitida ishga tushirish uchun mo'ljallangan.

---

## 📋 1. Talab Qilinadigan Resurslar (Server Requirements)

* **OS**: Ubuntu 22.04 LTS yoki Ubuntu 24.04 LTS
* **CPU**: Kamida 2 vCPU (Tavsiya: 4 vCPU)
* **RAM**: Kamida 4 GB RAM (Tavsiya: 8 GB RAM)
* **Disk**: 40+ GB NVMe SSD
* **Ochiq portlar**:
  - `80/tcp` (HTTP - Caddy)
  - `443/tcp` va `443/udp` (HTTPS & HTTP/3 QUIC - Caddy)
  - `3478/tcp` va `3478/udp` (Coturn WebRTC STUN/TURN)
  - `49152-65535/udp` (Coturn Media Relay ports)

---

## 🛠️ 2. Serverni Tayyorlash (Server Setup)

Serverga SSH orqali ulaning:
```bash
ssh root@your_server_ip
```

Tizimni yangilang va Docker hamda Docker Compose o'rnating:
```bash
# Paketlar ro'yxatini yangilash
sudo apt update && sudo apt upgrade -y

# Kerakli utilitalar
sudo apt install -y curl git ufw fail2ban

# Rasmiy Docker o'rnatish
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Docker Compose plaginini tekshirish
docker compose version
```

Xavfsizlik devorini (Firewall) sozlang:
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 443/udp
sudo ufw allow 3478/tcp
sudo ufw allow 3478/udp
sudo ufw allow 49152:65535/udp
sudo ufw enable
```

---

## 🌐 3. Domen va DNS Sozlash

Domen boshqaruv panelingizda (Cloudflare, Reg.ru, GoDaddy yoki boshqa provayder):
1. **A Record**: `app.yourdomain.uz` ➡️ `Serveringiz IP manzili`
2. **A Record**: `api.yourdomain.uz` (ixtiyoriy) ➡️ `Serveringiz IP manzili`

*(Agar Cloudflare ishlatsangiz, WebRTC va WebSockets barqaror ishlashi uchun proxy rejimini (Orange Cloud) o'chirib qo'yish yoki WebSockets opsiyasini yoqish tavsiya etiladi).*

---

## 📦 4. Loyiha Kodini Yuklash & Konfiguratsiya

```bash
# Loyiha papkasiga o'tish
cd /opt
git clone <Sizning_Git_Repozitoriyangiz_URL> logiflow
cd logiflow

# Production muhit faylini yaratish
cp .env.example .env

# Faylni tahrirlash
nano .env
```

### Muhim `.env` Parametrlari:
* `ENVIRONMENT=production`
* `DEBUG=false`
* `DOMAIN_NAME=app.yourdomain.uz` (O'z domeningizni yozing)
* `ACME_EMAIL=admin@yourdomain.uz` (Let's Encrypt SSL xabarnomalari uchun)
* `SECRET_KEY`: Yangi xavfsiz kalit hosil qiling (`openssl rand -hex 32`)
* `DB_PASSWORD`: PostgreSQL uchun qat'iy parol kiriting
* `ESKIZ_EMAIL` va `ESKIZ_PASSWORD`: Real SMS yuborish uchun Eskiz.uz kalitlari
* `PAYME_SECRET_KEY` va `CLICK_SECRET_KEY`: O'zbekiston to'lov provayderlari kalitlari

---

## 🚀 5. Ishga Tushirish (Deploy via Docker Compose)

Konteynerlarni bir buyruq bilan yig'ing va fonda ishga tushiring:
```bash
docker compose -f docker-compose.prod.yml up --build -d
```

Ishga tushgan konteynerlar holatini tekshirish:
```bash
docker compose -f docker-compose.prod.yml ps
```

Konteynerlar ro'yxatida quyidagi 6 ta xizmat bo'lishi kerak:
1. `logiflow_caddy_prod` (Up, 80, 443)
2. `logiflow_backend_prod` (Up)
3. `logiflow_frontend_prod` (Up)
4. `logiflow_postgres_prod` (healthy)
5. `logiflow_redis_prod` (healthy)
6. `logiflow_coturn_prod` (Up, 3478)

---

## 🔍 6. Salomatlik Tekshiruvi (Healthcheck)

Serveringiz brauzerda yoki curl orqali tekshiring:
```bash
# Backend Healthcheck
curl -I https://app.yourdomain.uz/health

# Natija:
# HTTP/2 200
# content-type: application/json
# {"status":"healthy","service":"LogiFlow Enterprise Logistics API", ...}
```

Brauzer orqali oching:
* **Flutter Web Ilova**: `https://app.yourdomain.uz`
* **Swagger API Hujjatlari**: `https://app.yourdomain.uz/docs`
* **ReDoc Hujjatlari**: `https://app.yourdomain.uz/redoc`

---

## 🔄 7. Yangilanishlarni O'rnatish (CI/CD Update Flow)

Kodingizga o'zgartirish kiritilganda serverda yangilash juda oson:
```bash
cd /opt/logiflow
git pull origin main
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

---

## 📊 8. Jurnallar va Monitoring (Logs)

Barcha xizmatlar jurnallarini real vaqtda kuzatish:
```bash
# Barcha loglar
docker compose -f docker-compose.prod.yml logs -f

# Faqat backend loglari
docker compose -f docker-compose.prod.yml logs -f backend

# Caddy SSL va kiruvchi so'rovlar
docker compose -f docker-compose.prod.yml logs -f caddy
```

---

## 💾 9. Ma'lumotlar Zaxira Nusxasi (Backup)

PostgreSQL bazasini zaxiralash:
```bash
docker exec -t logiflow_postgres_prod pg_dumpall -c -U logiflow_user > /opt/backups/backup_$(date +%F).sql
```
