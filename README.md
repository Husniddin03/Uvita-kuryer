# Uvita Courier

Uvita omborsiz marketplace'i uchun Flutter courier ilovasi. Courier yukni seller
manzilidan olib, to'g'ridan-to'g'ri xaridorga yetkazadi.

## Asosiy oqim

1. Courier profil va transport imkoniyatlarini ko'radi.
2. Og'irlik, hajm, masofa, yo'nalish va qarz holatiga mos trip offer oladi.
3. Tripni qabul qiladi; pickupgacha default 1 soat ichida sabab bilan bekor qilishi mumkin.
4. Sellerda miqdor, sifat/brak, qadoq va tashish shartini tekshiradi.
5. Handover tasdiqlangach order yo'lda holatiga o'tadi.
6. Customerdan aniq naqd summani oladi.
7. Customer SMS PIN bilan deliveryni tasdiqlaydi.
8. Courier cash liability va earning ilovada ko'rinadi.
9. Tripdan keyin pul topshirish so'rovi yuboradi.

Kamida 90% naqd pul topshirilmasa yangi trip bloklanadi. Qolgan qarz default 3 kun
ichida yopiladi. Qisman deliveryda actual quantity, sabab va media dalil majburiy.

## Texnologiyalar

- Flutter/Dart
- `provider`
- `http`
- `flutter_map` va OpenStreetMap
- `geolocator`
- Firebase Messaging va local notifications

## Ishga tushirish

Flutter 3.27+ tavsiya qilinadi.

```bash
flutter pub get
flutter run
```

API manzili `lib/config.dart` yoki amaldagi environment konfiguratsiyasidan olinadi.
Android emulator uchun odatda `http://10.0.2.2:8000/api`, haqiqiy qurilmada HTTPS
yoki lokal tarmoq manzili ishlatiladi.

## Tekshiruv

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Xavfsizlik

- Token logga chiqarilmaydi.
- Courier faqat o'z assigned trip/delivery ma'lumotini ko'radi.
- GPS faqat active trip davomida minimal zarur chastotada yuboriladi.
- PIN clientda tekshirilmaydi; yakuniy tasdiq backendda.
- Offline/retry duplicate pickup, delivery yoki ledger yozuvi yaratmasligi kerak.

Yagona biznes manba: `../uvita_backend/LIFECYCLE.md`.
