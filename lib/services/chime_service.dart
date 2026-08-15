import 'package:flutter/services.dart';

/// Yangi buyurtma signali.
///
/// Flutter'da web'deki kabi Web Audio API yo'q — `SystemSound` tizim signalini
/// ishlatadi (asset fayl talab qilinmaydi). Android'da qisqa "ding" yangraydi.
class ChimeService {
  ChimeService._();

  static bool enabled = true;

  /// Yangi buyurtma kelganda chalinadi.
  static Future<void> play() async {
    if (!enabled) return;
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // Ovoz ishlamasa — jim o'tamiz
    }
  }
}
