/// Buyurtma modeli — backend `/api/courier/orders` javobiga mos.
class OrderItem {
  final int productId;
  final String productName;
  final int price;
  final int quantity;
  final int subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: (json['product_id'] ?? json['id'] ?? 0) as int,
        productName: (json['product_name'] ?? 'Mahsulot') as String,
        price: (json['price'] ?? 0) as int,
        quantity: (json['quantity'] ?? 1) as int,
        subtotal: (json['subtotal'] ?? 0) as int,
      );
}

class OrderAddress {
  final String region;
  final String district;
  final String street;
  final String house;
  final String landmark;

  OrderAddress({
    this.region = '',
    this.district = '',
    this.street = '',
    this.house = '',
    this.landmark = '',
  });

  factory OrderAddress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OrderAddress();
    return OrderAddress(
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      street: json['street'] ?? '',
      house: json['house'] ?? '',
      landmark: json['landmark'] ?? '',
    );
  }

  String get full =>
      [region, district, street, house].where((s) => s.isNotEmpty).join(', ');
}

/// "Topilmadi" urinishi ma'lumoti.
class DeliveryAttempt {
  final int number;
  final String reasonCode;
  final String reasonNote;
  final String? attemptedAt;

  DeliveryAttempt({
    required this.number,
    required this.reasonCode,
    required this.reasonNote,
    this.attemptedAt,
  });

  factory DeliveryAttempt.fromJson(Map<String, dynamic> json) =>
      DeliveryAttempt(
        number: (json['number'] ?? 0) as int,
        reasonCode: (json['reason_code'] ?? 'other') as String,
        reasonNote: (json['reason_note'] ?? '') as String,
        attemptedAt: json['attempted_at'] as String?,
      );
}

class Order {
  final int id;
  final String status;
  final String phone;
  final String phoneSecondary;
  final String courierNote;
  final OrderAddress address;
  final double? lat;
  final double? lng;
  final String? geoLevel;
  final String deliveryTime;
  final String createdAt;
  final String? deliveredAt;
  final int totalPrice;
  final int serviceFee;
  final int grandTotal;
  final int courierFee;
  final int notFoundCount;
  final List<OrderItem> items;
  final List<DeliveryAttempt> attempts;

  Order({
    required this.id,
    required this.status,
    required this.phone,
    required this.phoneSecondary,
    required this.courierNote,
    required this.address,
    this.lat,
    this.lng,
    this.geoLevel,
    required this.deliveryTime,
    required this.createdAt,
    this.deliveredAt,
    required this.totalPrice,
    required this.serviceFee,
    required this.grandTotal,
    required this.courierFee,
    required this.notFoundCount,
    required this.items,
    required this.attempts,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Courier resursida: delivery_location { latitude, longitude }
    final dl = json['delivery_location'];
    double? dLat;
    double? dLng;
    if (dl is Map) {
      dLat = (dl['latitude'] as num?)?.toDouble();
      dLng = (dl['longitude'] as num?)?.toDouble();
    }
    // Customer resursida: lat / lng
    dLat ??= (json['lat'] as num?)?.toDouble();
    dLng ??= (json['lng'] as num?)?.toDouble();

    return Order(
      id: (json['id'] ?? 0) as int,
      status: (json['status'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      phoneSecondary: (json['phone_secondary'] ?? '') as String,
      courierNote: (json['courier_note'] ?? '') as String,
      address: OrderAddress.fromJson(
          json['address'] is Map ? json['address'] as Map<String, dynamic> : null),
      lat: dLat,
      lng: dLng,
      geoLevel: json['geo_level'] as String?,
      deliveryTime: (json['delivery_time'] ?? '') as String,
      createdAt: (json['created_at'] ?? '') as String,
      deliveredAt: (json['delivered_at'] as String?) ?? (json['completed_at'] as String?),
      totalPrice: (json['total_price'] ?? 0) as int,
      serviceFee: (json['service_fee'] ?? 0) as int,
      grandTotal: (json['grand_total'] ?? 0) as int,
      courierFee: (json['courier_fee'] ?? 0) as int,
      notFoundCount: (json['not_found_count'] ?? 0) as int,
      items: ((json['items'] as List?) ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      attempts: ((json['attempts'] as List?) ?? [])
          .map((e) => DeliveryAttempt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<Order> listFromJson(List<dynamic>? list) =>
      (list ?? []).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();

  /// Yangi (qabul qilinmagan) — tayinlangan, kuryer qabul qilmagan
  bool get isNew => status == 'ready_to_deliver';

  /// Aktiv (qabul qilingan, yo'lda)
  bool get isActive => status == 'delivering';

  /// Yetkazish manzili qisqa: "Yunusobod tumani"
  String get shortArea {
    final parts = <String>[
      address.district,
      address.region,
    ].where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'Manzil ko\'rsatilmagan';
    return parts.join(', ');
  }

  /// Yo'nalish: "Chilonzor → Yunusobod" ko'rinishida
  String get routeLabel {
    final from = [address.region].where((s) => s.isNotEmpty).toList();
    final to = [address.district, address.street]
        .where((s) => s.isNotEmpty)
        .toList();
    if (from.isEmpty && to.isEmpty) return 'Manzil ko\'rsatilmagan';
    if (to.isEmpty) return from.join(', ');
    return '${from.isEmpty ? 'Do\'kon' : from.join(', ')} → ${to.join(', ')}';
  }
}
