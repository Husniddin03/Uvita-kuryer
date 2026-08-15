import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class GeoPoint {
  final double lat;
  final double lng;

  /// Nominatim reverse-geocode'dan manzil komponentlari
  String region = '';
  String district = '';
  String street = '';
  String house = '';

  GeoPoint(this.lat, this.lng);

  GeoPoint.withAddress({
    required this.lat,
    required this.lng,
    this.region = '',
    this.district = '',
    this.street = '',
    this.house = '',
  });
}

class RouteInfo {
  final List<GeoPoint> points;
  final double distanceMeters;
  final double durationSeconds;
  RouteInfo(this.points, this.distanceMeters, this.durationSeconds);
}

/// Nominatim (geokodlash) va OSRM (marshrut) bilan ishlash.
/// Bepul xizmatlar — kalit talab qilinmaydi.
class GeocodeService {
  GeocodeService._();

  static final Map<String, Future<GeoPoint?>> _geocodeCache = {};
  static final Map<String, Future<GeoPoint?>> _reverseCache = {};

  static const _userAgent = 'UvitaCourier/1.0 (mobile)';

  /// Manzil matnini geokodlaydi (to'liq manzil → koordinata).
  static Future<GeoPoint?> geocode(String query) {
    if (query.trim().isEmpty) return Future.value(null);
    if (_geocodeCache.containsKey(query)) return _geocodeCache[query]!;

    final future = _doGeocode(query);
    _geocodeCache[query] = future;
    return future;
  }

  static Future<GeoPoint?> _doGeocode(String query) async {
    try {
      final uri = Uri.parse(AppConfig.nominatimSearch).replace(
        queryParameters: {
          'format': 'jsonv2',
          'limit': '1',
          'countrycodes': 'uz',
          'q': query,
        },
      );
      final res = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      });
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as List;
      if (data.isEmpty) return null;
      final first = data.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;
      return _withParts(GeoPoint(lat, lng), first['display_name']);
    } catch (_) {
      return null;
    }
  }

  /// Koordinatani teskari geokodlaydi (nuqta → manzil komponentlari).
  static Future<GeoPoint?> reverse(double lat, double lng) {
    final key = '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
    if (_reverseCache.containsKey(key)) return _reverseCache[key]!;

    final future = _doReverse(lat, lng);
    _reverseCache[key] = future;
    return future;
  }

  static Future<GeoPoint?> _doReverse(double lat, double lng) async {
    try {
      final uri = Uri.parse(
              'https://nominatim.openstreetmap.org/reverse')
          .replace(queryParameters: {
        'format': 'jsonv2',
        'lat': '$lat',
        'lon': '$lng',
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'uz',
      });
      final res = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      });
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = data['address'];
      if (addr is! Map) return null;

      final a = addr as Map<String, dynamic>;
      final city = (a['city'] ?? a['town'] ?? a['village'] ?? '')
          .toString()
          .replaceAll(RegExp(r' shahri$'), '')
          .trim();
      final isNeighborhood = RegExp(r'mahalla|маҳалла', caseSensitive: false)
          .hasMatch(city);

      return GeoPoint.withAddress(
        lat: lat,
        lng: lng,
        region: _cleanRegion(
            (a['state'] ?? a['region'] ?? (city.isNotEmpty && !isNeighborhood ? city : '')).toString()),
        district: (a['county'] ??
                a['city_district'] ??
                a['suburb'] ??
                a['municipality'] ??
                (isNeighborhood ? city : ''))
            .toString(),
        street: (a['road'] ?? a['pedestrian'] ?? a['footway'] ?? '').toString(),
        house: (a['house_number'] ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// "Samarqand viloyati" → "Samarqand"
  static String _cleanRegion(String s) => s
      .replaceAll(RegExp(r'\s+(Viloyati|viloyati|Viloyat|viloyat)$'), '')
      .trim();

  static GeoPoint _withParts(GeoPoint p, String? display) {
    final parts = (display ?? '').split(', ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      p.region = _cleanRegion(parts[1]);
      p.district = parts[0];
    }
    return p;
  }

  /// OSRM orqali ikki nuqta orasidagi marshrut.
  static Future<RouteInfo?> route(GeoPoint from, GeoPoint to) async {
    try {
      final uri = Uri.parse(
          '${AppConfig.osrmRoute}/${from.lng},${from.lat};${to.lng},${to.lat}'
          '?overview=full&geometries=geojson');
      final res = await http.get(uri, headers: {'User-Agent': _userAgent});
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final coords = (route['geometry'] as Map<String, dynamic>)['coordinates']
          as List;
      final points = coords
          .map((c) => GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      return RouteInfo(
        points,
        (route['distance'] as num).toDouble(),
        (route['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
