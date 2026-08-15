import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Backend bilan ishlash uchun yagona HTTP client.
/// Har bir so'rovda token qo'shiladi (auth: Bearer).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static String? _token;

  /// 401 (token eskirgan) kelganda chaqiriladi — AuthProvider uni ulaydi
  /// va sessiyani tozalab kirish sahifasiga qaytaradi.
  static void Function()? onUnauthorized;

  /// Joriy API bazasi. Profil sahifasidagi "Server manzili" sozlamasi
  /// orqali o'zgartiriladi (ngrok URL kabi) — rebuild shart emas.
  static String _baseUrl = AppConfig.apiBase;

  static const _timeout = Duration(seconds: 15);

  static String get baseUrl => _baseUrl;

  static void setToken(String? token) => _token = token;

  /// Saqlangan API manzilini yuklaydi (app ishga tushganda chaqiriladi).
  /// Foydalanuvchi o'zi kiritmagan bo'lsa — build vaqtidagi default qoladi.
  static Future<void> loadSavedBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(AppConfig.savedApiBaseKey);
      if (saved != null && saved.trim().isNotEmpty) {
        final url = _normalize(saved);
        if (url != null) _baseUrl = url;
      }
    } catch (_) {
      // SharedPreferences xatosi — default bilan davom etamiz
    }
  }

  /// API manzilini o'zgartiradi va SharedPreferences'ga saqlaydi.
  /// Qaytish qiymati: normalizatsiyalangan URL (xato bo'lsa null).
  static Future<String?> setBaseUrl(String raw) async {
    final url = _normalize(raw);
    if (url == null) return null;
    _baseUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.savedApiBaseKey, url);
    } catch (_) {}
    return url;
  }

  /// URL'ni normalizatsiya qiladi:
  ///  - http/https prefiksi yo'q bo'lsa qo'shiladi
  ///    (localhost/private IP -> http, boshqa -> https)
  ///  - oxiridagi '/' olib tashlanadi
  ///  - `/api` suffiksi bo'lmasa qo'shiladi
  static String? _normalize(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;

    final hasScheme = s.startsWith('http://') || s.startsWith('https://');
    if (!hasScheme) {
      // localhost / private IP uchun http (https ishlamaydi), boshqasi uchun https
      final hostOnly = s.split('/').first;
      final isLocal = hostOnly == 'localhost' ||
          hostOnly.startsWith('127.') ||
          hostOnly.startsWith('10.') ||
          hostOnly.startsWith('192.168.') ||
          hostOnly.startsWith('172.') ||
          hostOnly == '[::1]';
      s = '${isLocal ? 'http' : 'https'}://$s';
    }
    s = s.replaceAll(RegExp(r'/+$'), '');
    // '/api' oxirgi yo'l segmenti bo'lsa qo'shilmaydi
    final path = Uri.tryParse(s)?.path ?? '';
    if (!path.endsWith('/api') && !path.contains('/api/')) s = '$s/api';
    // Oddiy URL tekshiruvi
    final uri = Uri.tryParse(s);
    if (uri == null || !uri.hasAuthority) return null;
    return s;
  }

  Map<String, String> _headers({bool json = true}) => {
        if (_token != null) 'Authorization': 'Bearer $_token',
        if (json) 'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));
    final res = await http.get(uri, headers: _headers()).timeout(_timeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.post(uri,
            headers: _headers(), body: jsonEncode(body ?? {}))
        .timeout(_timeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.put(uri,
            headers: _headers(), body: jsonEncode(body ?? {}))
        .timeout(_timeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.delete(uri, headers: _headers()).timeout(_timeout);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body = {};
    try {
      if (res.body.isNotEmpty) body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      // JSON bo'lmagan javob — bo'sh body deb qaraymiz
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    // Token eskirgan/noto'g'ri — sessiyani tozalab kirishga qaytaramiz.
    // Polling 401 xatosini qayta-qayta ko'rsatmasligi uchun bir marta chaqiriladi.
    if (res.statusCode == 401 && _token != null) {
      _token = null;
      onUnauthorized?.call();
    }

    final message = (body['message'] as String?) ??
        (body['data'] is String ? body['data'] as String : null) ??
        'Xatolik yuz berdi (${res.statusCode})';
    throw ApiException(message, statusCode: res.statusCode);
  }
}
