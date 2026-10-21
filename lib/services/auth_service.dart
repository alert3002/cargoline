import 'dart:convert';

import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// HTTP client for Cargo Line TJ auth API (OsonSMS via backend).
class AuthService {
  AuthService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  static String get defaultBaseUrl => BrandConstants.apiBaseUrl;
  static const Duration requestTimeout = Duration(seconds: 8);
  static const Duration smsTimeout = Duration(seconds: 25);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _authHeaders(String? token) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> sendCode(String phone) async {
    final response = await _client
        .post(
          _uri('/api/v1/auth/send-code'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': _formatPhone(phone)}),
        )
        .timeout(smsTimeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> verifyCode(String phone, String code) async {
    final response = await _client
        .post(
          _uri('/api/v1/auth/verify-code'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': _formatPhone(phone),
            'code': code.trim(),
          }),
        )
        .timeout(smsTimeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> ensureSession({
    required String phone,
    String? clientCode,
  }) async {
    final response = await _client
        .post(
          _uri('/api/v1/auth/ensure-session'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': _formatPhone(phone),
            if (clientCode != null) 'client_code': clientCode,
          }),
        )
        .timeout(requestTimeout);
    return _decode(response);
  }

  Future<void> deleteAccount(String token) async {
    final response = await _client
        .delete(
          _uri('/api/v1/auth/account'),
          headers: _authHeaders(token),
        )
        .timeout(requestTimeout);
    _decode(response);
  }

  Future<Map<String, dynamic>> fetchMe(String token) async {
    final response = await _client
        .get(
          _uri('/api/v1/auth/me'),
          headers: _authHeaders(token),
        )
        .timeout(requestTimeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? firstName,
    String? lastName,
    String? birthDate,
    String? workPhone,
    String? address,
    String? avatarUrl,
  }) async {
    final response = await _client
        .put(
          _uri('/api/v1/auth/profile'),
          headers: _authHeaders(token),
          body: jsonEncode({
            if (firstName != null) 'first_name': firstName,
            if (lastName != null) 'last_name': lastName,
            if (birthDate != null) 'birth_date': birthDate,
            if (workPhone != null) 'work_phone': workPhone,
            if (address != null) 'address': address,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          }),
        )
        .timeout(requestTimeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> sendEmailCode(String email) async {
    final response = await _client
        .post(
          _uri('/api/v1/auth/send-email-code'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(requestTimeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> verifyEmailCode(String email, String code) async {
    final response = await _client
        .post(
          _uri('/api/v1/auth/verify-email-code'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'code': code.trim(),
          }),
        )
        .timeout(requestTimeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> loginWithGoogleToken({
    required String idToken,
    String? email,
    String? name,
  }) async {
    final response = await _client
        .post(
          _uri('/api/v1/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id_token': idToken,
            if (email != null) 'email': email,
            if (name != null) 'name': name,
          }),
        )
        .timeout(requestTimeout);
    return _decode(response);
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('992') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.length == 9) {
      return '+992$digits';
    }
    return phone.trim();
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'raw': decoded};
    } catch (_) {
      throw AuthException(
        'Сервер вернул некорректный ответ (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final detail = body['detail'];
    String message;
    if (detail is String) {
      message = detail;
    } else if (detail is Map) {
      final oson = detail['osonsms'];
      message = oson?.toString() ?? detail.toString();
    } else {
      message = 'Ошибка авторизации (${response.statusCode})';
    }
    throw AuthException(message, statusCode: response.statusCode);
  }
}
