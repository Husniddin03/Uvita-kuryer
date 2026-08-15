import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/order.dart';
import '../screens/order_detail_screen.dart';

/// Yangi buyurtma haqida lokal bildirishnoma (Android).
///
/// - Ilova ochiq yoki fonda (orqada) turganda ishlaydi — tizim panelida
///   banner chiqadi, ovoz yangraydi.
/// - Ilova butunlay o'chirilgan bo'lsa ishlamaydi — buning uchun FCM push
///   (Firebase) kerak bo'ladi.
///
/// Bildirishnomani bosganda buyurtma tafsilotlari ochiladi.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'new_orders';
  static const String _channelName = 'Yangi buyurtmalar';
  static const String _channelDesc = 'Yangi buyurtma biriktirilganda xabar beriladi';

  static bool _initialized = false;

  /// FCM orqali allaqachon e'lon qilingan buyurtmalar — polling qayta
  /// notification chiqarmasligi uchun (ikkita xabar ko'rinmasligi kerak).
  static final Map<int, DateTime> _announcedAt = {};

  /// Bildirishnomani bosganda buyurtma sahifasiga o'tish uchun.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Buyurtma haqida xabar berilganini belgilaydi (FCM tizim ko'rsatganda).
  static void markAnnounced(int orderId) {
    _announcedAt[orderId] = DateTime.now();
  }

  /// Shu buyurtma haqida yaqinda (10 daqiqa ichida) xabar berilganmi?
  static bool isAnnounced(int orderId) {
    final at = _announcedAt[orderId];
    if (at == null) return false;
    return DateTime.now().difference(at) < const Duration(minutes: 10);
  }

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
    );
  }

  /// Android 13+ da bildirishnoma ruxsatini so'raydi.
  static Future<bool> requestPermission() async {
    await init();
    final impl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null) return true;
    final granted = await impl.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Yangi buyurtma kelganda tizim bildirishnomasini chiqaradi.
  /// (Local polling aniqlaganda ishlatiladi.)
  static Future<void> showNewOrder(Order order, {bool sound = true}) async {
    await showPush(
      orderId: order.id,
      title: '🛵 Yangi buyurtma #${order.id}',
      body: order.address.full.isEmpty
          ? 'Jami: ${_fmtMoney(order.grandTotal)} so\'m'
          : '${order.address.full} · ${_fmtMoney(order.grandTotal)} so\'m',
      sound: sound,
    );
  }

  /// FCM push yoki local aniqlangan xabarni tizim bildirishnomasi sifatida
  /// chiqaradi. Id = orderId, bosilganda buyurtma sahifasi ochiladi.
  ///
  /// Ilova butunlay yopiq (terminated) bo'lsa ham FCM data-only xabar
  /// background handler orqali shu metodga keladi.
  static Future<void> showPush({
    required int orderId,
    required String title,
    required String body,
    bool sound = true,
  }) async {
    await init();

    final details = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: sound,
      enableVibration: sound,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
    );

    await _plugin.show(
      id: orderId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: details),
      payload: '$orderId',
    );
  }

  /// 62100 -> "62 100"
  static String _fmtMoney(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  static int? _pendingOrderId;

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final id = int.tryParse(payload);
    if (id == null) return;
    openOrder(id);
  }

  /// Buyurtma sahifasini ochadi (FCM tap yoki local notification tap).
  /// Navigator tayyor bo'lmasa — birinchi frame'dan keyin ochiladi.
  static void openOrder(int orderId) {
    final nav = navigatorKey?.currentState;
    if (nav == null) {
      // Cold-start: navigator hali tayyor emas
      _pendingOrderId = orderId;
      return;
    }
    _pushOrder(nav, orderId);
  }

  /// Cold-start'da kechiktirilgan navigatsiyani bajaradi (birinchi frame'dan keyin).
  static void consumePending() {
    final id = _pendingOrderId;
    if (id == null) return;
    _pendingOrderId = null;
    final nav = navigatorKey?.currentState;
    if (nav != null) _pushOrder(nav, id);
  }

  static void _pushOrder(NavigatorState nav, int id) {
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(orderId: id),
      ),
    );
  }
}
