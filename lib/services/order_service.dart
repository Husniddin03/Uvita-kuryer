import '../models/courier.dart';
import '../models/order.dart';
import 'api_client.dart';

/// Kuryer buyurtmalari bilan ishlash.
class OrderService {
  OrderService._();

  /// Faol buyurtmalar ro'yxati: `/api/courier/orders`
  static Future<List<Order>> getOrders() async {
    final res = await ApiClient.instance.get('/courier/orders');
    return Order.listFromJson(res['data'] as List?);
  }

  /// Bitta buyurtma: `/api/courier/orders/{id}`
  static Future<Order> getOrder(int id) async {
    final res = await ApiClient.instance.get('/courier/orders/$id');
    final data = res['data'];
    return Order.fromJson(data is Map ? data as Map<String, dynamic> : {});
  }

  /// Statistik: `/api/courier/stats`
  static Future<CourierStats> getStats() async {
    final res = await ApiClient.instance.get('/courier/stats');
    final data = res['data'] ?? res;
    return CourierStats.fromJson(
        data is Map ? data as Map<String, dynamic> : {});
  }

  /// Daromad: `/api/courier/earnings`
  static Future<CourierEarnings> getEarnings() async {
    final res = await ApiClient.instance.get('/courier/earnings');
    final data = res['data'] ?? res;
    return CourierEarnings.fromJson(
        data is Map ? data as Map<String, dynamic> : {});
  }

  /// Tarix: `/api/courier/history?page=N`
  static Future<List<Order>> getHistory({int page = 1}) async {
    final res =
        await ApiClient.instance.get('/courier/history', query: {'page': page});
    return Order.listFromJson(res['data'] as List?);
  }

  /// FCM device token'ni backend'ga ro'yxatdan o'tkazish: POST /staff/device-token
  static Future<void> registerDeviceToken(String token) async {
    await ApiClient.instance.post('/staff/device-token', {
      'token': token,
      'platform': 'android',
    });
  }

  /// Profil: `/api/courier/profile`
  static Future<CourierProfile> getProfile() async {
    final res = await ApiClient.instance.get('/courier/profile');
    final data = res['data'];
    return CourierProfile.fromJson(
        data is Map ? data as Map<String, dynamic> : {});
  }

  /// Onlayn/oflayn holat: PUT /courier/availability
  /// Qaytadi: (is_online, shift_started_at)
  static Future<({bool isOnline, String? shiftStartedAt})> setAvailability(
      bool isOnline) async {
    final res = await ApiClient.instance
        .put('/courier/availability', {'is_online': isOnline});
    final data = res['data'];
    if (data is! Map) return (isOnline: isOnline, shiftStartedAt: null);
    return (
      isOnline: (data['is_online'] ?? isOnline) as bool,
      shiftStartedAt: data['shift_started_at'] as String?,
    );
  }

  /// Buyurtmani qabul qilish ("Zakazni oldim"): PUT /courier/orders/{id}/accept
  static Future<Order> accept(int id) async {
    final res = await ApiClient.instance.put('/courier/orders/$id/accept');
    final data = res['data'];
    return Order.fromJson(data is Map ? data as Map<String, dynamic> : {});
  }

  /// Tayinlovni rad etish: PUT /courier/orders/{id}/reject
  static Future<Order> reject(int id, {String reason = 'band'}) async {
    final res = await ApiClient.instance
        .put('/courier/orders/$id/reject', {'reason': reason});
    final data = res['data'];
    return Order.fromJson(data is Map ? data as Map<String, dynamic> : {});
  }

  /// Yetkazildi (mijozdan olingan 4 xonali PIN bilan):
  /// PUT /courier/orders/{id}/delivered
  static Future<Order> deliver(
    int id, {
    required String pin,
    String? recipientName,
    double? latitude,
    double? longitude,
  }) async {
    final res = await ApiClient.instance.put('/courier/orders/$id/delivered', {
      'pin': pin,
      if (recipientName != null && recipientName.isNotEmpty)
        'recipient_name': recipientName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    final data = res['data'];
    return Order.fromJson(data is Map ? data as Map<String, dynamic> : {});
  }

  /// Topilmadi (4 sababdan biri): PUT /courier/orders/{id}/not-found
  static Future<Order> markNotFound(
    int id, {
    required String reasonCode,
    String? reasonNote,
    double? latitude,
    double? longitude,
  }) async {
    final res = await ApiClient.instance.put('/courier/orders/$id/not-found', {
      'reason_code': reasonCode,
      if (reasonNote != null && reasonNote.isNotEmpty)
        'reason_note': reasonNote,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    final data = res['data'];
    return Order.fromJson(data is Map ? data as Map<String, dynamic> : {});
  }

  /// Qo'llab-quvvatlash so'rovlari: GET /courier/support
  static Future<List<Map<String, dynamic>>> getSupport() async {
    final res = await ApiClient.instance.get('/courier/support');
    final data = res['data'];
    if (data is List) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Qo'llab-quvvatlash so'rovi yuborish: POST /courier/support
  /// Backend `category` kutadi (subject emas!): delivery/customer/vehicle/accident/app/other
  static Future<void> createSupport({
    required String category,
    required String message,
    int? orderId,
  }) async {
    await ApiClient.instance.post('/courier/support', {
      'category': category,
      'message': message,
      if (orderId != null) 'order_id': orderId,
    });
  }

  /// Bildirishnomalar: GET /courier/notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final res = await ApiClient.instance.get('/courier/notifications');
    final data = res['data'];
    if (data is List) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Bildirishnomani o'qilgan deb belgilash: PUT /courier/notifications/{id}/read
  static Future<void> markNotificationRead(int id) async {
    await ApiClient.instance.put('/courier/notifications/$id/read');
  }

  /// Jonli joylashuv yuborish: POST /courier/locations
  /// (order_id — ayni paytda yetkazilayotgan zakaz bo'lishi kerak)
  static Future<void> saveLocation({
    required int orderId,
    required double latitude,
    required double longitude,
    int? accuracy,
  }) async {
    await ApiClient.instance.post('/courier/locations', {
      'order_id': orderId,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Profilni yangilash: PUT /courier/profile
  static Future<CourierProfile> updateProfile({
    required String name,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    double? vehicleCapacityKg,
    int? maxOrdersPerTrip,
  }) async {
    final res = await ApiClient.instance.put('/courier/profile', {
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (vehicleType != null && vehicleType.isNotEmpty)
        'vehicle_type': vehicleType,
      if (vehicleNumber != null && vehicleNumber.isNotEmpty)
        'vehicle_number': vehicleNumber,
      if (vehicleCapacityKg != null) 'vehicle_capacity_kg': vehicleCapacityKg,
      if (maxOrdersPerTrip != null) 'max_orders_per_trip': maxOrdersPerTrip,
    });
    final data = res['data'];
    return CourierProfile.fromJson(
        data is Map ? data as Map<String, dynamic> : {});
  }
}
