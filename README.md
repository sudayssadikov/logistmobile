# LogiFlow - Raqamli Logistika va Yuk Tashish Platformasi

LogiFlow — O'zbekiston va Markaziy Osiyo bozoriga mo'ljallangan zamonaviy, xavfsiz va to'liq avtomatlashtirilgan yuk logistikasi platformasi. Tizim Flutter (mobil ilova, Neumorphism UI dizayni) va FastAPI (asinxron Python backend, SQLite/PostgreSQL, SQLAlchemy 2.0) arxitekturasi asosida qurilgan.

---

## 🚀 Asosiy Imkoniyatlar va Arxitektura

### 1. Qat'iy Rollar Tizimi (RBAC)
- **Faqat 2 ta foydalanuvchi roli:**
  - `SHIPPER` (Yuk Beruvchi): Yuk e'lon qilish, takliflarni ko'rib chiqish va qabul qilish, Escrow to'lovini muzlatish, yukni kuzatish va qabul qilish.
  - `DRIVER` (Haydovchi / Tashuvchi): E'lon qilingan yuklar lentasini ko'rish, narx taklif qilish (bidding), tayinlangan reyslarni boshqarish, GPS orqali statuslarni yangilash va to'lovni qabul qilish.
- **ShellRoute orqali to'liq ajratilgan navigatsiya:**
  - `ShipperShell`: Bosh sahifa | Yuk qo'shish | Yuklarim | Chat | Profil
  - `DriverShell`: Yuklar (Feed) | Reyslarim | Chat | Profil
- **Login/Register Segmentatsiyasi:** Boshlang'ich ekranda 2 ta aniq segment; agar haydovchi yuk beruvchi sifatida kirishga urinsa yoki aksincha, tizim kirishga yo'l qo'ymaydi va to'g'ri segmentni taklif qiladi. Hech qanday soxta (mock) login yoki aylanma yo'l (backdoor) mavjud emas.

### 2. Xarita va Geomanzillar Qatlami
- Abstract `MapProvider` interfeysi orqali xarita tizimi ajratilgan.
- Hozirgi integratsiya: `flutter_map` + OpenStreetMap (OSM) plitkalari, Nominatim orqali geokodlash (debounce va User-Agent cheklovlariga amal qilingan holda).
- `LocationPickerScreen`: Interaktiv xarita, qidiruv maydoni, markaziy pin orqali aniq nuqta tanlash va reverse-geocoding.
- Masofani hisoblash: Haversine formulasi orqali taxminiy masofa (km) avtomatik hisoblanadi.

### 3. Escrow Kafolatli To'lov va Pog'onali Komissiya
LogiFlow moliyaviy xavfsizlikni ikki yoqlama buxgalteriya (Double-entry ledger) va Escrow depozit tizimi orqali ta'minlaydi:
- **Yuk beruvchi:** Shartlashilgan aniq summani to'laydi (hech qanday ustama yoki yashirin to'lovsiz).
- **Mablag'ni ushlab turish (Hold):** Haydovchi tayinlangach, yuk beruvchi [To'lash] tugmasini bosadi va mablag' platforma Escrow depozitida muzlatiladi.
- **Pog'onali platforma komissiyasi (Tiered Commission):**
  - **1-pog'ona:** $\le 2,000,000$ UZS $\rightarrow$ **30,000 UZS**
  - **2-pog'ona:** $2,000,000 - 5,000,000$ UZS $\rightarrow$ **50,000 UZS**
  - **3-pog'ona:** $> 5,000,000$ UZS $\rightarrow$ **70,000 UZS**
- **To'lovni chiqarish (Release):** Yuk manzilga yetkazilib, qabul qilingandan so'ng, komissiya faqat haydovchining sof tushumidan ushlab qolinadi va sof summa haydovchi hamyoniga o'tkaziladi.
- **100% Qaytarish (Refund):** Agar yuk bekor qilinsa, Escrow'dagi to'liq summa 0% komissiya bilan yuk beruvchiga qaytariladi.

### 4. Muloqot va Xavfsizlik Qoidalari (Chat & VoIP Call)
- **Chat:** Faqat yukka haydovchi rasman tayinlangandan (`CARRIER_ASSIGNED` / `ASSIGNED`) so'ng ochiladi. Tayinlanmagan yuklar bo'yicha haydovchi xabar yoza olmaydi. Yuk yetkazilgach (`DELIVERED`) yoki bekor qilingach (`CANCELLED`), chat avtomatik ravishda **faqat o'qish rejimiga** o'tadi.
- **Qo'ng'iroq va Telefon Raqamlari:** Haydovchi telefon raqami to'lov Escrow'ga muzlatilgunga qadar niqoblangan bo'ladi (`+998 90 *** ** 12`). VoIP audio qo'ng'iroq faqat Escrow muzlatilgandan so'ng yoqiladi.

### 5. Bildirishnomalar (In-App & Push)
- Asosiy bosqichlarda avtomatik bildirishnoma yaratiladi:
  - Yangi taklif (bid) kelganda $\rightarrow$ Yuk beruvchiga
  - Taklif qabul qilinganda $\rightarrow$ Haydovchiga
  - To'lov Escrow'ga muzlatilganda $\rightarrow$ Haydovchiga
  - Yuk yo'lga chiqqanda va yetkazilganda $\rightarrow$ Yuk beruvchiga
  - Yangi xabar yuborilganda $\rightarrow$ Qabul qiluvchiga
- FCM (Firebase Cloud Messaging) qurilma tokenlarini saqlash endpointi (`/api/v1/notifications/device-token`) mavjud.

---

## 💳 To'lov Tizimlari: Payme va Click (Sandbox & Production)

Hozirgi holatda backend'da Payme va Click integratsiyasi Sandbox/Mock rejimida sozlangan:
- **Payme Webhook:** `/api/v1/payments/webhooks/payme` (`CheckPerformTransaction`, `PerformTransaction` metodlari to'liq protokoli bilan).
- **Click Webhook:** `/api/v1/payments/webhooks/click` (`Prepare` va `Complete` bosqichlari).

### Production muhitiga o'tish talablari:
1. Payme Merchant API va Click Merchant kabinetlaridan rasmiy `MERCHANT_ID`, `SECRET_KEY`, `SERVICE_ID` kalitlarini olish.
2. Serverda SSL sertifikati (HTTPS) o'rnatilgan bo'lishi va merchant kabinetida Webhook URL ro'yxatdan o'tkazilishi.
3. `.env` faylida quyidagi parametrlarni to'ldirish:
   ```env
   PAYME_MERCHANT_ID=your_production_merchant_id
   PAYME_SECRET_KEY=your_production_secret_key
   CLICK_MERCHANT_ID=your_production_click_merchant_id
   CLICK_SERVICE_ID=your_production_click_service_id
   CLICK_SECRET_KEY=your_production_click_secret_key
   ```
4. IP Oq ro'yxati (Whitelist): Faqat Payme (`185.196.214.*`, `195.158.31.*`) va Click rasmiy serverlaridan kelgan so'rovlarni qabul qilish.

---

## 🛡️ Xavfsizlik va Hardening Auditi

| Endpoint Guruhi | Rol Tekshiruvi (RBAC) | Resurs Egaligi (Ownership) | Rate Limiting | Holati |
|---|---|---|---|---|
| `POST /auth/login` | Mavjud (Rollar mosligi) | — | 10 req/min | Himoyalangan |
| `POST /auth/send-otp` | Umumiy | — | 5 req/2min | Himoyalangan |
| `POST /shipments` | Faqat `SHIPPER` | Egasi avtomatik `user.id` | — | Himoyalangan |
| `GET /shipments` | Rol bo'yicha filter | Shipper faqat o'zinikini ko'radi | — | Himoyalangan |
| `POST /shipments/{id}/bids` | Faqat `DRIVER` | Driver id bog'lanadi | — | Himoyalangan |
| `POST /bids/{id}/accept` | Faqat `SHIPPER` | Faqat yuk egasi qabul qiladi | — | Himoyalangan |
| `POST /escrow/fund` | Faqat `SHIPPER` | Faqat yuk egasi to'laydi | — | Himoyalangan |
| `POST /calls/initiate` | Ishtirokchi tekshiruvi | Escrow muzlatilmagan bo'lsa 403 | — | Himoyalangan |
| `POST /chat/{id}/messages` | Ishtirokchi tekshiruvi | Faqat ishtirokchilar; Yakunlansa 403 | — | Himoyalangan |
| `GET /wallet` | Barcha rollar | Faqat o'z hamyoni | — | Himoyalangan |

- **Production Mode:** `ENVIRONMENT=production` bo'lganda `/docs`, `/redoc` va `/openapi.json` avtomatik tarzda butunlay yopiladi.
- **Maxfiylik:** `.env` va uning barcha variantlari `.gitignore`ga kiritilgan, git repozitoriyasiga tushmaydi.

---

### 6. Yuklar Boshqaruvi va Tarixi (`loads` moduli - 3-qism)
- **Yagona manba (Single source of truth):** Yangi yuk tizimi `loads` jadvaliga asoslangan. Eski `shipments` jadvallari bilan to'qnashuvlar to'liq bartaraf etilgan.
- **Ruxsatlar va Holatlar Matritsasi:**
  | Holat (`status`) | Ko'rish | Barcha maydonlarni tahrirlash | Cheklangan tahrir (izoh, soat) | Bekor qilish | Nusxa ko'chirish |
  |---|---|---|---|---|---|
  | `ACTIVE` | ✅ | ✅ | ✅ | ✅ | ✅ |
  | `ASSIGNED` | ✅ | ❌ (409) | ✅ | ✅ | ✅ |
  | `IN_TRANSIT` | ✅ | ❌ (409) | ❌ (409) | ❌ (409) | ✅ |
  | `DELIVERED` | ✅ | ❌ (409) | ❌ (409) | ❌ (409) | ✅ |
  | `CANCELLED` | ✅ | ❌ (409) | ❌ (409) | ❌ (409) | ✅ |
- **Parallel tahrirdan himoya (Optimistic Locking):** Har bir PATCH so'rovida `updatedAt` tekshiriladi; agar yuk boshqa joyda o'zgartirilgan bo'lsa, 409 xatolik qaytariladi va foydalanuvchiga ma'lumotlarni yangilash taklif etiladi.
- **Hodisalar jurnali (`load_events`):** Har bir yuk yaratilishi (`CREATED`), tahrirlanishi (`EDITED`), bekor qilinishi (`CANCELLED`) yoki nusxalanishi (`DUPLICATED`) vaqt tamg'asi va muallifi bilan saqlanadi.
- **Dev-status endpointi:**
  - `POST /api/v1/loads/{id}/dev-status` (body: `{"status": "ASSIGNED"}`) — qo'lda test qilish va statuslarni o'zgartirish uchun yordamchi endpoint. `ENVIRONMENT=production` bo'lganda avtomatik ravishda bloklanadi (403).

---

## 🧪 Sinov Natijalari (Verification)

Barcha backend va mobil testlar 100% yashil:

```bash
# Backend testlari (25 ta test)
pytest -v backend/tests
# Natija: 25 passed, 7 warnings in 30.19s

# Flutter statik tahlili
flutter analyze
# Natija: No issues found! (0 errors, 0 warnings, 0 lints)

# Flutter birlik va vidjet testlari (36 ta test)
flutter test
# Natija: 00:16 +36: All tests passed!
```

---

## 📱 Ishga Tushirish Yo'riqnomasi

### Backend:
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
python -m uvicorn app.main:app --reload --port 8000
```

### Flutter Mobil Ilova:
```bash
flutter pub get
flutter run
```
Release APK yig'ish:
```bash
flutter build apk --release
```
