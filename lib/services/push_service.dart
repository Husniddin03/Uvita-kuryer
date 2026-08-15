import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';
import 'order_service.dart';

/// FCM (Firebase Cloud Messaging) push integratsiyasi.
///
/// Backend data-only xabar yuboradi: {order_id, title, body, sound}.
/// - Ilova ochiq (foreground):  onMessage → lokal bildirishnoma
/// - Ilova fonda yoki butunlay yopiq: onBackgroundMessage (headless isolate)
///   → lokal bildirishnoma. Shuning uchun push hatto app o'chirilganda ham keladi.
/// - Xabarni bosganda: buyurtma tafsiloti ochiladi.
class PushService {
  PushService._();

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Firebase sozlanmagan bo'lsa (google-services.json yo'q) xato yutib yuboriladi —
  /// app lokal bildirishnoma + polling bilan ishlashda davom etadi.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      // Foreground xabar → lokal bildirishnoma
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Notification bosilganda (app fonda/ochiq) → buyurtma sahifasi
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedApp);

      // App terminated holatda notification orqali ochilganda
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _onOpenedApp(initial);

      // Token yangilansa — backend'ga qayta yuboramiz
      _messaging.onTokenRefresh.listen((_) => registerToken());
    } catch (_) {
      // Firebase sozlanmagan — jim o'tamiz
    }
  }

  /// Joriy FCM token'ni backend'ga ro'yxatdan o'tkazadi (login'dan keyin).
  static Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await OrderService.registerDeviceToken(token);
    } catch (_) {
      // Tarmoq xatosi — keyingi urinishda yana bo'ladi
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    // Foreground'da tizim notification'ni ko'rsatmaydi — o'zimiz ko'rsatamiz.
    // Background'da esa payload notification'ni tizim o'zi ko'rsatadi.
    final data = message.data;
    final orderId = int.tryParse(data['order_id'] ?? '');
    if (orderId == null) return;
    // Foreground ham, polling ham chaqirishi mumkin — ikki marta emas.
    if (NotificationService.isAnnounced(orderId)) return;
    NotificationService.markAnnounced(orderId);
    await NotificationService.showPush(
      orderId: orderId,
      title: message.notification?.title ?? data['title'] ?? 'Yangi buyurtma',
      body: message.notification?.body ?? data['body'] ?? '',
      sound: data['sound'] != 'off',
    );
  }

  static void _onOpenedApp(RemoteMessage message) {
    final id = int.tryParse(message.data['order_id'] ?? '');
    if (id != null) NotificationService.openOrder(id);
  }
}

/// FCM background handler — headless izolyatsiyada ishlaydi, widget yo'q.
/// App butunlay yopiq bo'lsa ham chaqiriladi.
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Xabarda 'notification' payload bo'lsa — Android tizimi o'zi ko'rsatadi,
  // biz qayta ko'rsatmaymiz (ikkita notification chiqmasligi uchun).
  // Data-only xabar bo'lsa (qo'lda yuborilgan) — o'zimiz ko'rsatamiz.
  final data = message.data;
  final orderId = int.tryParse(data['order_id'] ?? '');
  if (orderId == null) return;

  if (message.notification != null) {
    // Tizim ko'rsatgan — polling qayta chiqarmasligi uchun belgilab qo'yamiz.
    NotificationService.markAnnounced(orderId);
    return;
  }

  try {
    await Firebase.initializeApp();
  } catch (_) {
    return;
  }
  NotificationService.markAnnounced(orderId);
  await NotificationService.showPush(
    orderId: orderId,
    title: data['title'] ?? 'Yangi buyurtma',
    body: data['body'] ?? '',
    sound: data['sound'] != 'off',
  );
}
