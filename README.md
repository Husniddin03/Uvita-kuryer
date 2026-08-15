# Uvita — Kuryer ilovasi (Flutter / Android)

Uvita Market oziq-ovqat do'koni uchun kuryer mobil ilovasi. Buyurtmalarni
qabul qilish, yetkazish, tarix va profil boshqaruvi — barchasi bitta ilovada.

## 🚀 Ishga tushirish

### 1. Flutter SDK o'rnatish

> **Talab:** Flutter **3.27+** (kod `Color.withValues` va `DialogThemeData`
> API'laridan foydalanadi). So'nggi stable versiyani o'rnating.

```bash
# Flutter'ni yuklab oling: https://docs.flutter.dev/get-started/install/linux
# (masalan: /home/user/flutter'ga oching)

export PATH="$PATH:$HOME/flutter/bin"
flutter doctor   # Android toolchain'ni tekshiring
```

### 2. Loyihani tayyorlash

```bash
cd Uvita_mobile
flutter pub get
```

> **Eslatma:** `android/` katalogi qo'lda yozilgan. Agar `flutter create` bilan
> loyiha yaratilgan bo'lsa va gradle xatosi bersa:
> ```bash
> flutter create . --platforms android
> ```
> — bu `android/`'dagi yetishmayotgan fayllarni to'ldiradi (mavjudlarini ustiga yozmaydi).

### 3. Qurilma/emulatorda ishga tushirish

```bash
# Emulator:
flutter run

# APK build:
flutter build apk --debug
flutter build apk --release
```

APK manzili: `build/app/outputs/flutter-apk/app-debug.apk` (yoki `app-release.apk`).

## ⚙️ API konfiguratsiyasi

`lib/config.dart` faylida:

```dart
static const String apiBase = 'http://10.0.2.2:8000/api';
```

- **Android emulator** → `http://10.0.2.2:8000/api` (localhost'ga ulanadi)
- **Haqiqiy qurilma** → kompyuterning LAN IP-manzili:
  ```dart
  static const String apiBase = 'http://192.168.1.10:8000/api';
  ```

Backend `Uvita_backend` da `php artisan serve --host=0.0.0.0 --port=8000`
yoki docker orqali ishga tushirilgan bo'lishi kerak.

## 📱 Imkoniyatlar

- **Kirish** — email + parol (faqat kuryerlar; backend `role.courier` ni tekshiradi)
- **Bosh sahifa** — statistika (yetkazilgan / faol / muvaffaqiyat / topilmadi),
  faol buyurtmalar ro'yxati, pull-to-refresh, ovoz tugmasi
- **Yangi buyurtma signali** — har 30 soniyada avtomatik yangilanadi; yangi
  buyurtma tushsa **ovozli signal** + **banner** (20 soniya ichida avtomatik yopiladi)
- **Buyurtma tafsiloti** — holat hero, manzil + **OSM xaritasi**, mijoz telefoni
  (qo'ng'iroq qilish), mahsulotlar, qabul qilish / yetkazildi / topilmadi
- **Xarita** — OSM (bepul), backend'dagi `lat/lng` yoki Nominatim geokodlash,
  "Mening joylashuvim" (geolokatsiya) + OSRM marshrut/uzoqlik
- **Tarix** — sahifalangan yetkazilgan buyurtmalar
- **Profil** — shaxsiy ma'lumotlar, statistika, muvaffaqiyat darajasi, chiqish

## 🧩 Texnologiyalar

| Paket | Vazifasi |
|---|---|
| `flutter_map` + `latlong2` | OSM xarita (bepul, kalitsiz) |
| `http` | API so'rovlar |
| `shared_preferences` | Token/sessiya saqlash |
| `geolocator` | "Mening joylashuvim" |
| `url_launcher` | Qo'ng'iroq qilish, xarita ochish |
| `provider` | Holat boshqaruvi |

## 🎨 Dizayn

Forest/lime palitrasi — veb-versiya (React) bilan bir xil:
`#0A2B1D` (forest-900), `#104528` (forest-700), `#C5F255` (leaf-400),
`#F6F8F6` (fon).

## 📁 Tuzilma

```
lib/
  main.dart              — ilova kirish nuqtasi
  config.dart            — API URL va xarita sozlamalari
  theme.dart             — ranglar va dizayn tizimi
  models/                — Order, CourierProfile, CourierStats
  services/              — ApiClient, AuthService, OrderService, GeocodeService, ChimeService
  providers/             — AuthProvider, OrderProvider (polling + signal)
  screens/               — Login, MainShell, Home, OrderDetail, History, Profile
  widgets/               — OrderCard, OrderBadge, AlertStack, DeliveryMap
```
