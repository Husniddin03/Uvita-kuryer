/// Kuryer profili — `/api/courier/profile`
class CourierProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String photo;
  final String vehicleType;
  final String vehicleNumber;
  final double vehicleCapacityKg;
  final int maxOrdersPerTrip;
  final bool isOnline;
  final String? shiftStartedAt;

  CourierProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.photo = '',
    this.vehicleType = '',
    this.vehicleNumber = '',
    this.vehicleCapacityKg = 1000,
    this.maxOrdersPerTrip = 10,
    this.isOnline = false,
    this.shiftStartedAt,
  });

  factory CourierProfile.fromJson(Map<String, dynamic> json) => CourierProfile(
        id: (json['id'] ?? 0) as int,
        name: (json['name'] ?? 'Kuryer') as String,
        email: (json['email'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        photo: (json['photo'] ?? '') as String,
        vehicleType: (json['vehicle_type'] ?? '') as String,
        vehicleNumber: (json['vehicle_number'] ?? '') as String,
        vehicleCapacityKg:
            (json['vehicle_capacity_kg'] as num?)?.toDouble() ?? 1000,
        maxOrdersPerTrip: (json['max_orders_per_trip'] as num?)?.toInt() ?? 10,
        isOnline: (json['is_online'] ?? false) as bool,
        shiftStartedAt: json['shift_started_at'] as String?,
      );

  CourierProfile copyWith({
    bool? isOnline,
    String? name,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    double? vehicleCapacityKg,
    int? maxOrdersPerTrip,
    String? shiftStartedAt,
  }) =>
      CourierProfile(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        photo: photo,
        vehicleType: vehicleType ?? this.vehicleType,
        vehicleNumber: vehicleNumber ?? this.vehicleNumber,
        vehicleCapacityKg: vehicleCapacityKg ?? this.vehicleCapacityKg,
        maxOrdersPerTrip: maxOrdersPerTrip ?? this.maxOrdersPerTrip,
        isOnline: isOnline ?? this.isOnline,
        shiftStartedAt: shiftStartedAt ?? this.shiftStartedAt,
      );
}

/// Kuryer statistikasi — `/api/courier/stats`
class CourierStats {
  final int totalDelivered;
  final int todayDelivered;
  final int totalActive;
  final int totalNotFound;
  final double? successRate;

  CourierStats({
    required this.totalDelivered,
    required this.totalActive,
    required this.totalNotFound,
    this.todayDelivered = 0,
    this.successRate,
  });

  factory CourierStats.fromJson(Map<String, dynamic> json) => CourierStats(
        totalDelivered: (json['total_delivered'] ?? 0) as int,
        todayDelivered: (json['today_delivered'] ?? 0) as int,
        totalActive: (json['total_active'] ?? 0) as int,
        totalNotFound: (json['total_not_found'] ?? 0) as int,
        successRate: (json['success_rate'] as num?)?.toDouble(),
      );
}

/// Kuryer daromadi — `/api/courier/earnings`
class CourierEarnings {
  final int today;
  final int thisWeek;
  final int thisMonth;
  final int totalEarned;
  final int paid;
  final int pendingPayout;
  final int unpaid;

  CourierEarnings({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.totalEarned,
    required this.paid,
    required this.pendingPayout,
    required this.unpaid,
  });

  factory CourierEarnings.fromJson(Map<String, dynamic> json) =>
      CourierEarnings(
        today: (json['today'] ?? 0) as int,
        thisWeek: (json['this_week'] ?? 0) as int,
        thisMonth: (json['this_month'] ?? 0) as int,
        totalEarned: (json['total_earned'] ?? 0) as int,
        paid: (json['paid'] ?? 0) as int,
        pendingPayout: (json['pending_payout'] ?? 0) as int,
        unpaid: (json['unpaid'] ?? 0) as int,
      );
}
