# LogiFlow Legacy Features & Screen Archive

Ushbu papkada tizimda 2 ta asosiy rol (SHIPPER va DRIVER) ga o'tilishi natijasida faol navigatsiyadan uzilgan, ammo kelajakda (admin portal, tashuvchi kengaytmasi va AI tahlil uchun) qayta ishlatilishi rejalashtirilgan komponentlar saqlanadi:

1. **Admin Control Center** (`features/admin/`):
   - Global nazorat minorasi, telemetriya nazorati, admin audit.
   - Login ekrani va mobil mijoz navigatsiyasidan uzilgan, backendda alohida `SystemRole.ADMIN` sifatida to'liq saqlanadi.

2. **Fleet Management** (`features/fleet/`):
   - Avtopark va yuk mashinalari parkini boshqarish (Carrier roli).
   - Rollar faqat Yuk beruvchi va Haydovchi qilib soddalashtirilgani sababli asosiy mobil oqimdan uzildi.

3. **AI Load Matcher** (`features/shipments/presentation/screens/ai_load_matcher_screen.dart`):
   - Yuklarni avtomatik moslashtirish ekrani keyingi bosqichlarda chuqurlashtiriladi.

4. **Carrier & Admin Dashboard Views** (`features/dashboard/presentation/widgets/`):
   - `carrier_dashboard_view.dart`
   - `admin_dashboard_view.dart`

