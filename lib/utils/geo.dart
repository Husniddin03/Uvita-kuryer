import 'dart:math' as math;

/// Geografik hisob-kitoblar: masofa (haversine) va taxminiy vaqt.
class GeoUtils {
  GeoUtils._();

  /// Ikki nuqta orasidagi to'g'ri chiziq masofasi (km).
  static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // Yer radiusi (km)
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  /// Taxminiy yetkazish vaqti (daqiqa): shahar ichida ~25-30 km/soat
  /// To'g'ri chiziq masofasi yo'l masofasidan qisqa — koeffitsiyent 1.4.
  static int etaMinutes(double km) {
    if (km <= 0) return 0;
    final road = km * 1.4;
    final min = road / 30 * 60; // 30 km/soat
    return (min + 3).round(); // +3 daq yuklash/uzatish
  }

  /// "8.4 km" formatida masofa
  static String kmLabel(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// "25 daqiqa" formatida vaqt
  static String etaLabel(int min) {
    if (min < 60) return '$min daqiqa';
    return '${min ~/ 60} soat ${min % 60} daq';
  }
}
