class TripRoute {
  final String key;
  final String origin;
  final String destination;
  final int ordersCount;
  final int pickupPointsCount;
  final double totalWeightKg;
  final int totalCourierFee;
  final String? oldestOrderAt;

  const TripRoute({
    required this.key,
    required this.origin,
    required this.destination,
    required this.ordersCount,
    required this.pickupPointsCount,
    required this.totalWeightKg,
    required this.totalCourierFee,
    this.oldestOrderAt,
  });

  factory TripRoute.fromJson(Map<String, dynamic> json) => TripRoute(
        key: '${json['key'] ?? ''}',
        origin: '${json['origin_region'] ?? ''}',
        destination: '${json['destination_region'] ?? ''}',
        ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
        pickupPointsCount: (json['pickup_points_count'] as num?)?.toInt() ?? 0,
        totalWeightKg: (json['total_weight_kg'] as num?)?.toDouble() ?? 0,
        totalCourierFee: (json['total_courier_fee'] as num?)?.toInt() ?? 0,
        oldestOrderAt: json['oldest_order_at'] as String?,
      );
}

class TripPreview {
  final int ordersCount;
  final int pickupPointsCount;
  final double capacityKg;
  final double totalWeightKg;
  final int cargoValue;
  final int courierFee;

  const TripPreview({
    required this.ordersCount,
    required this.pickupPointsCount,
    required this.capacityKg,
    required this.totalWeightKg,
    required this.cargoValue,
    required this.courierFee,
  });

  factory TripPreview.fromJson(Map<String, dynamic> json) => TripPreview(
        ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
        pickupPointsCount: (json['pickup_points_count'] as num?)?.toInt() ?? 0,
        capacityKg: (json['capacity_kg'] as num?)?.toDouble() ?? 0,
        totalWeightKg: (json['total_weight_kg'] as num?)?.toDouble() ?? 0,
        cargoValue: (json['cargo_value'] as num?)?.toInt() ?? 0,
        courierFee: (json['total_courier_fee'] as num?)?.toInt() ?? 0,
      );
}

class TripLocation {
  final double latitude;
  final double longitude;
  const TripLocation(this.latitude, this.longitude);

  static TripLocation? fromJson(dynamic json) {
    if (json is! Map) return null;
    final lat = json['latitude'] as num?;
    final lng = json['longitude'] as num?;
    return lat == null || lng == null
        ? null
        : TripLocation(lat.toDouble(), lng.toDouble());
  }
}

class PickupPoint {
  final String key;
  final int sequence;
  final String businessName;
  final String phone;
  final String region;
  final String district;
  final String address;
  final int ordersCount;
  final double weightKg;
  final bool pickedUp;
  final TripLocation? location;

  const PickupPoint({
    required this.key,
    required this.sequence,
    required this.businessName,
    required this.phone,
    required this.region,
    required this.district,
    required this.address,
    required this.ordersCount,
    required this.weightKg,
    required this.pickedUp,
    this.location,
  });

  factory PickupPoint.fromJson(Map<String, dynamic> json) => PickupPoint(
        key: '${json['key'] ?? ''}',
        sequence: (json['sequence'] as num?)?.toInt() ?? 0,
        businessName: '${json['business_name'] ?? 'Seller'}',
        phone: '${json['phone'] ?? ''}',
        region: '${json['region'] ?? ''}',
        district: '${json['district'] ?? ''}',
        address: '${json['address'] ?? ''}',
        ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
        pickedUp: json['picked_up'] == true,
        location: TripLocation.fromJson(json['location']),
      );
}

class TripDelivery {
  final int orderId;
  final int sequence;
  final String phone;
  final Map<String, dynamic> address;
  final String deliveryScope;
  final int cashDue;
  final int courierFee;
  final bool delivered;
  final TripLocation? location;
  final List<Map<String, dynamic>> items;

  const TripDelivery({
    required this.orderId,
    required this.sequence,
    required this.phone,
    required this.address,
    required this.deliveryScope,
    required this.cashDue,
    required this.courierFee,
    required this.delivered,
    required this.items,
    this.location,
  });

  factory TripDelivery.fromJson(Map<String, dynamic> json) => TripDelivery(
        orderId: (json['order_id'] as num?)?.toInt() ?? 0,
        sequence: (json['sequence'] as num?)?.toInt() ?? 0,
        phone: '${json['phone'] ?? ''}',
        address: Map<String, dynamic>.from(json['address'] as Map? ?? {}),
        deliveryScope: '${json['delivery_scope'] ?? 'district_center'}',
        cashDue: (json['cash_due'] as num?)?.toInt() ?? 0,
        courierFee: (json['courier_fee'] as num?)?.toInt() ?? 0,
        delivered: json['delivered'] == true,
        location: TripLocation.fromJson(json['location']),
        items: (json['items'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}

class CourierTrip {
  final int id;
  final String origin;
  final String destination;
  final String status;
  final double capacityKg;
  final double totalWeightKg;
  final int ordersCount;
  final int cargoValue;
  final int totalCourierFee;
  final int cashCollected;
  final int? platformCashDue;
  final bool addressesRevealed;
  final List<PickupPoint> pickups;
  final List<TripDelivery> deliveries;

  const CourierTrip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.status,
    required this.capacityKg,
    required this.totalWeightKg,
    required this.ordersCount,
    required this.cargoValue,
    required this.totalCourierFee,
    required this.cashCollected,
    required this.addressesRevealed,
    required this.pickups,
    required this.deliveries,
    this.platformCashDue,
  });

  bool get completed => status == 'completed';
  bool get pickingUp => status == 'picking_up';

  factory CourierTrip.fromJson(Map<String, dynamic> json) {
    final route = Map<String, dynamic>.from(json['route'] as Map? ?? {});
    return CourierTrip(
      id: (json['id'] as num?)?.toInt() ?? 0,
      origin: '${route['origin_region'] ?? ''}',
      destination: '${route['destination_region'] ?? ''}',
      status: '${json['status'] ?? ''}',
      capacityKg: (json['capacity_kg'] as num?)?.toDouble() ?? 0,
      totalWeightKg: (json['total_weight_kg'] as num?)?.toDouble() ?? 0,
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      cargoValue: (json['cargo_value'] as num?)?.toInt() ?? 0,
      totalCourierFee: (json['total_courier_fee'] as num?)?.toInt() ?? 0,
      cashCollected: (json['cash_collected'] as num?)?.toInt() ?? 0,
      platformCashDue: (json['platform_cash_due'] as num?)?.toInt(),
      addressesRevealed: json['customer_addresses_revealed'] == true,
      pickups: (json['pickup_points'] as List? ?? const [])
          .map((e) => PickupPoint.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      deliveries: (json['deliveries'] as List? ?? const [])
          .map(
              (e) => TripDelivery.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
