import '../models/trip.dart';
import 'api_client.dart';

class TripService {
  TripService._();

  static Future<List<TripRoute>> routes() async {
    final res = await ApiClient.instance.get('/courier/trip-routes');
    return (res['data'] as List? ?? const [])
        .map((e) => TripRoute.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<TripPreview> preview(String routeKey,
      {double? capacityKg}) async {
    final res = await ApiClient.instance.post('/courier/trips/preview', {
      'route_key': routeKey,
      if (capacityKg != null) 'capacity_kg': capacityKg,
    });
    return TripPreview.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  static Future<CourierTrip> create(String routeKey,
      {double? capacityKg}) async {
    final res = await ApiClient.instance.post('/courier/trips', {
      'route_key': routeKey,
      if (capacityKg != null) 'capacity_kg': capacityKg,
    });
    return CourierTrip.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  static Future<CourierTrip?> active() async {
    final res = await ApiClient.instance.get('/courier/trips/active');
    if (res['data'] is! Map) return null;
    return CourierTrip.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  static Future<CourierTrip> pickup(int tripId, String pickupKey) async {
    final res = await ApiClient.instance
        .put('/courier/trips/$tripId/pickups/$pickupKey');
    return CourierTrip.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  static Future<void> cancel(int tripId, String reason) async {
    await ApiClient.instance.put('/courier/trips/$tripId/cancel', {
      'reason': reason,
    });
  }

  static Future<CourierTrip> deliver({
    required int tripId,
    required int orderId,
    required String pin,
    required int cashReceived,
  }) async {
    final res = await ApiClient.instance
        .put('/courier/trips/$tripId/orders/$orderId/delivered', {
      'pin': pin,
      'cash_received': cashReceived,
    });
    return CourierTrip.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}
