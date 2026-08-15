import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/courier.dart';
import 'api_client.dart';

/// Xodim (kuryer) autentifikatsiyasi.
class AuthService {
  static const _tokenKey = 'auth_token';
  static const _profileKey = 'auth_profile';

  /// Kuryer uchun mavjud saqlangan sessiyani qaytaradi.
  static Future<({String token, CourierProfile profile})?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final raw = prefs.getString(_profileKey);
    if (token == null || raw == null) return null;
    try {
      final profile =
          CourierProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return (token: token, profile: profile);
    } catch (_) {
      return null;
    }
  }

  /// `/api/staff/login` — email + parol bilan kirish.
  /// Javob: `{ data: { token, user: {...} } }`
  static Future<CourierProfile> login(String email, String password) async {
    final res = await ApiClient.instance.post('/staff/login', {
      'email': email.trim(),
      'password': password,
    });

    final data = (res['data'] ?? {}) as Map<String, dynamic>;
    final token = (data['token'] ?? '') as String;
    // Backend javobida `staff` kaliti ishlatiladi: { staff: {...}, token: '...' }
    final userRaw = data['staff'] ?? data['user'] ?? data['profile'] ?? {};

    final Map<String, dynamic> user =
        userRaw is Map ? userRaw as Map<String, dynamic> : {};

    final profile = CourierProfile(
      id: (user['id'] ?? 0) as int,
      name: (user['name'] ?? 'Kuryer') as String,
      email: (user['email'] ?? email) as String,
      isOnline: (user['is_online'] ?? false) as bool,
    );

    // Kuryer bo'lmagan xodim kirishiga yo'l qo'ymaymiz
    if ((user['role'] ?? '') != 'courier') {
      throw ApiException('Bu ilova faqat kuryerlar uchun');
    }

    if (token.isEmpty) throw ApiException('Token olinmadi');

    ApiClient.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_profileKey, jsonEncode({
      'id': profile.id,
      'name': profile.name,
      'email': profile.email,
      'is_online': profile.isOnline,
    }));

    return profile;
  }

  /// Tokenni o'chirish (chiqish).
  static Future<void> logout() async {
    try {
      await ApiClient.instance.post('/staff/logout');
    } catch (_) {
      // Server xatosi chiqishni bloklamaydi
    }
    await clearLocalSession();
  }

  /// Lokal sessiyani tozalash (401 / logout). Serverga so'rov yubormaydi.
  static Future<void> clearLocalSession() async {
    ApiClient.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_profileKey);
  }
}
