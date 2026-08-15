import 'package:flutter/foundation.dart';

import '../models/courier.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  CourierProfile? _profile;

  AuthStatus get status => _status;
  CourierProfile? get profile => _profile;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Ilova ochilganda saqlangan sessiyani tiklash.
  Future<void> restore() async {
    final session = await AuthService.restore();
    if (session != null) {
      ApiClient.setToken(session.token);
      _profile = session.profile;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      final profile = await AuthService.login(email, password);
      _profile = profile;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _profile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Token eskirganida (401) sessiyani lokal tozalaydi — serverga so'rov
  /// yubormaydi (u ham 401 qaytarishi mumkin). ApiClient.onUnauthorized ulaydi.
  void forceLogout() {
    AuthService.clearLocalSession();
    _profile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Serverdan olingan profil ma'lumotini yangilash (masalan, Profile sahifasi).
  void updateProfile(CourierProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  /// Profilni serverdan qayta yuklash (shift/avtomobil ma'lumotlari yangilanadi).
  Future<void> refreshProfile() async {
    try {
      final p = await OrderService.getProfile();
      _profile = p;
      notifyListeners();
    } catch (_) {
      // Sessiyadagi ma'lumot yetarli
    }
  }
}
