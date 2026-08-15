import 'package:geolocator/geolocator.dart';

import 'notification_service.dart';

/// Ruxsatlarni boshqarish: joylashuv + bildirishnoma.
class PermissionService {
  PermissionService._();

  /// Joylashuv ruxsatini tekshiradi va kerak bo'lsa so'raydi.
  /// `true` — ruxsat bor (whileInUse yoki always).
  static Future<bool> ensureLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  /// Ruxsat umuman berilmagan (deniedForever) yoki hali so'ralmaganmi?
  static Future<bool> isLocationDeniedForever() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.deniedForever;
  }

  /// Android 13+ da bildirishnoma ruxsatini so'raydi.
  static Future<bool> ensureNotifications() =>
      NotificationService.requestPermission();

  /// Ilovaga birinchi kirganda barcha ruxsatlarni so'raydi.
  static Future<void> requestAll() async {
    await ensureNotifications();
    await ensureLocation();
  }

  /// Ilova sozlamalari sahifasini ochadi (deniedForever holatida).
  static Future<void> openSettings() => Geolocator.openAppSettings();
}
