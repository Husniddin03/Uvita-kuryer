/// Uvita kuryer ilovasi konfiguratsiyasi.
///
/// API manzili build vaqtida beriladi:
///  - Emulator: `flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api` (default)
///  - Haqiqiy telefon (USB): avval `adb reverse tcp:8000 tcp:8000`,
///    keyin `flutter run --dart-define=API_BASE=http://127.0.0.1:8000/api`
///  - LAN: `flutter run --dart-define=API_BASE=http://192.168.1.10:8000/api`
///  - Internet (ngrok): Profil sahifasidagi "Server manzili" sozlamasidan
///    kiritiladi — rebuild shart emas.
class AppConfig {
  AppConfig._();

  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  /// SharedPreferences kalitlari (API sozlamasi)
  static const String savedApiBaseKey = 'saved_api_base';

  /// OSM tile'lar (bepul, kalit talab qilinmaydi)
  static const String mapTileUrl =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapAttribution = '© OpenStreetMap contributors';

  /// Nominatim geokodlash (bepul)
  static const String nominatimSearch =
      'https://nominatim.openstreetmap.org/search';

  /// OSRM marshrut (bepul demo server)
  static const String osrmRoute = 'https://router.project-osrm.org/route/v1/driving';
}
