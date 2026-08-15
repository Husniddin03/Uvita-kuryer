import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/courier.dart';
import '../models/order.dart';
import '../services/chime_service.dart';
import '../services/geocode_service.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../services/permission_service.dart';
import '../utils/geo.dart';

class OrderProvider extends ChangeNotifier {
  List<Order>? _orders;
  CourierStats? _stats;
  CourierEarnings? _earnings;
  List<Order> _alerts = [];
  String? _error;
  DateTime? _lastUpdate;
  bool _soundOn = true;

  /// Kuryer joylashuvi (masofa hisoblash uchun) + har bir zakaz uchun keshlangan
  GeoPoint? _courierPos;
  DateTime? _posFetchedAt;
  final Map<int, ({double km, int min})> _metrics = {};

  Timer? _pollTimer;
  Timer? _locationTimer;
  final Map<int, Timer> _dismissTimers = {};
  final Set<int> _seenIds = {};
  bool _initialized = false;

  List<Order>? get orders => _orders;
  CourierStats? get stats => _stats;
  CourierEarnings? get earnings => _earnings;
  List<Order> get alerts => _alerts;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  bool get soundOn => _soundOn;
  int get activeCount => _orders?.length ?? 0;

  /// Yangi zakazlar (qabul qilinmagan)
  List<Order> get newOrders =>
      (_orders ?? []).where((o) => o.isNew).toList();

  /// Aktiv zakazlar (qabul qilingan, yo'lda) — eng yaqini birinchi.
  /// Masofa/vaqt hisoblanmaganlar oxiriga qo'yiladi.
  List<Order> get activeOrders {
    final list = (_orders ?? []).where((o) => o.isActive).toList();
    list.sort((a, b) {
      final ma = _metrics[a.id];
      final mb = _metrics[b.id];
      if (ma == null && mb == null) return 0;
      if (ma == null) return 1;
      if (mb == null) return -1;
      return ma.km.compareTo(mb.km);
    });
    return list;
  }

  /// Zakaz uchun masofa/vaqt (keshlangan).
  ({double km, int min})? metricsFor(Order o) => _metrics[o.id];

  /// 30 soniyada avtomatik yangilashni boshlash.
  Future<void> start() async {
    _stopPolling();
    _seenIds.clear();
    _initialized = false;
    _alerts = [];
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    _soundOn = prefs.getBool('courier_sound') ?? true;
    ChimeService.enabled = _soundOn;

    _fetchCourierPosition();
    await refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    // Onlayn + aktiv (delivering) zakaz bo'lsa — joylashuvni backend'ga yuborish
    _startLocationReporting();
  }

  /// Onlayn holatda va ayni paytda yetkazilayotgan zakaz bo'lsa, har 20 soniyada
  /// kuryer joylashuvini `/courier/locations` ga yuboradi (admin xaritada ko'radi).
  void _startLocationReporting() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final delivering =
          (_orders ?? []).where((o) => o.isActive).toList();
      if (delivering.isEmpty) return;
      // Onlayn ekanligini profil orqali bilmaymiz — aktiv zakaz bor bo'lsa yuboramiz
      try {
        final granted = await PermissionService.ensureLocation();
        if (!granted) return;
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        await OrderService.saveLocation(
          orderId: delivering.first.id,
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy?.round(),
        );
      } catch (_) {
        // GPS yo'q yoki tarmoq xatosi — keyingi davrda qayta uriniladi
      }
    });
  }

  /// Polling va banner timerlarini to'xtatish (logout'da chaqiriladi).
  void stop() {
    if (_pollTimer == null && _alerts.isEmpty && _locationTimer == null) return;
    _stopPolling();
    _alerts = [];
    _seenIds.clear();
    _initialized = false;
    notifyListeners();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _locationTimer?.cancel();
    _locationTimer = null;
    for (final t in _dismissTimers.values) {
      t.cancel();
    }
    _dismissTimers.clear();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  /// Kuryer joylashuvini oladi (60 soniyada bir marta) — masofa hisoblash uchun.
  Future<void> _fetchCourierPosition() async {
    if (_posFetchedAt != null &&
        DateTime.now().difference(_posFetchedAt!) < const Duration(seconds: 60)) {
      return;
    }
    _posFetchedAt = DateTime.now();
    try {
      final granted = await PermissionService.ensureLocation();
      if (!granted) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );
      _courierPos = GeoPoint(pos.latitude, pos.longitude);
      // Yangi hisob-kitob
      _metrics.clear();
    } catch (_) {
      // GPS yo'q — masofa ko'rsatilmaydi
    }
  }

  /// Buyurtmalar + statistika + daromad yangilash.
  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        OrderService.getOrders(),
        OrderService.getStats(),
        OrderService.getEarnings(),
      ]);
      final list = results[0] as List<Order>;
      final stats = results[1] as CourierStats;
      final earnings = results[2] as CourierEarnings;

      _orders = list;
      _stats = stats;
      _earnings = earnings;
      _lastUpdate = DateTime.now();
      _error = null;

      // Masofa hisoblash (kuryer joylashuvi bor bo'lsa)
      if (_courierPos != null) {
        for (final o in list) {
          if (o.lat != null && o.lng != null) {
            final km = GeoUtils.haversineKm(
                _courierPos!.lat, _courierPos!.lng, o.lat!, o.lng!);
            _metrics[o.id] = (km: km, min: GeoUtils.etaMinutes(km));
          }
        }
      }

      // Birinchi yuklash: mavjud buyurtmalar "eski" deb belgilanadi — signal yo'q
      if (!_initialized) {
        _initialized = true;
        for (final o in list) {
          _seenIds.add(o.id);
        }
      } else {
        final fresh = list.where((o) => !_seenIds.contains(o.id)).toList();
        if (fresh.isNotEmpty) {
          for (final o in fresh) {
            _seenIds.add(o.id);
          }
          _alerts = [
            ...fresh,
            ..._alerts.where((a) => !fresh.any((f) => f.id == a.id)),
          ].take(3).toList();
          ChimeService.play();
          for (final o in fresh) {
            if (NotificationService.isAnnounced(o.id)) continue;
            NotificationService.markAnnounced(o.id);
            NotificationService.showNewOrder(o, sound: _soundOn);
          }
          for (final o in fresh) {
            _dismissTimers[o.id]?.cancel();
            _dismissTimers[o.id] = Timer(
              const Duration(seconds: 20),
              () => _dismissAlert(o.id),
            );
          }
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Buyurtmani qabul qilish ("Zakazni oldim").
  Future<Order> accept(Order order) async {
    final updated = await OrderService.accept(order.id);
    await _applyUpdate(updated);
    return updated;
  }

  /// Tayinlovni rad etish.
  Future<Order> reject(Order order) async {
    final updated = await OrderService.reject(order.id, reason: 'band');
    await _applyUpdate(updated);
    return updated;
  }

  /// Yetkazish (PIN bilan) — muvaffaqiyatli bo'lsa ro'yxatdan o'chadi.
  Future<Order> deliver(
    Order order, {
    required String pin,
    String? recipientName,
    double? latitude,
    double? longitude,
  }) async {
    final updated = await OrderService.deliver(
      order.id,
      pin: pin,
      recipientName: recipientName,
      latitude: latitude,
      longitude: longitude,
    );
    _removeFromList(order.id);
    return updated;
  }

  /// Topilmadi.
  Future<Order> markNotFound(
    Order order, {
    required String reasonCode,
    String? reasonNote,
    double? latitude,
    double? longitude,
  }) async {
    final updated = await OrderService.markNotFound(
      order.id,
      reasonCode: reasonCode,
      reasonNote: reasonNote,
      latitude: latitude,
      longitude: longitude,
    );
    await _applyUpdate(updated);
    return updated;
  }

  Future<void> _applyUpdate(Order updated) async {
    final list = [...?_orders];
    final i = list.indexWhere((o) => o.id == updated.id);
    if (i >= 0) {
      list[i] = updated;
    } else {
      list.insert(0, updated);
    }
    _orders = list;
    notifyListeners();
  }

  void _removeFromList(int id) {
    _orders = (_orders ?? []).where((o) => o.id != id).toList();
    _alerts = _alerts.where((a) => a.id != id).toList();
    _metrics.remove(id);
    notifyListeners();
  }

  void dismissAlert(int id) => _dismissAlert(id);

  void _dismissAlert(int id) {
    _dismissTimers[id]?.cancel();
    _dismissTimers.remove(id);
    _alerts = _alerts.where((a) => a.id != id).toList();
    notifyListeners();
  }

  /// Ovoz tugmasi — sozlama SharedPreferences'da saqlanadi.
  Future<void> toggleSound() async {
    _soundOn = !_soundOn;
    ChimeService.enabled = _soundOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('courier_sound', _soundOn);
    notifyListeners();
  }
}
