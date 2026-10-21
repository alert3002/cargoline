import 'dart:convert';

import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/models/parcel.dart';
import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// HTTP API for parcels (requires Bearer access_token).
class ParcelApi {
  ParcelApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AuthService.defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<Parcel>> listParcels(String token) async {
    final response = await _client.get(
      _uri('/api/v1/parcels/'),
      headers: _headers(token),
    );
    final body = _decode(response);
    final list = body is List ? body : (body['items'] as List? ?? const []);
    return list
        .map((e) => Parcel.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<Parcel> addParcel({
    required String token,
    required String trackCode,
    required MarketplaceKey marketplace,
    required String pickupPoint,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/parcels/add'),
      headers: _headers(token),
      body: jsonEncode({
        'track_code': trackCode,
        'marketplace': marketplace.name,
        'pickup_point': pickupPoint,
      }),
    );
    final body = _decode(response);
    return Parcel.fromApi(body as Map<String, dynamic>);
  }

  Future<void> deleteParcel(String token, String trackCode) async {
    final response = await _client.delete(
      _uri('/api/v1/parcels/${Uri.encodeComponent(trackCode)}'),
      headers: _headers(token),
    );
    _decode(response);
  }

  Future<void> updatePayment({
    required String token,
    required String paymentMethod,
    List<String>? trackCodes,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/parcels/payment'),
      headers: _headers(token),
      body: jsonEncode({
        'payment_method': paymentMethod,
        if (trackCodes != null && trackCodes.isNotEmpty)
          'track_codes': trackCodes,
      }),
    );
    _decode(response);
  }

  Future<void> updateFulfillment({
    required String token,
    required String fulfillment,
    List<String>? trackCodes,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/parcels/fulfillment'),
      headers: _headers(token),
      body: jsonEncode({
        'fulfillment': fulfillment,
        if (trackCodes != null && trackCodes.isNotEmpty)
          'track_codes': trackCodes,
      }),
    );
    _decode(response);
  }

  Future<Parcel> adminScan({
    required String trackCode,
    required String newStatus,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/admin/scan-parcel'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'track_code': trackCode,
        'new_status': newStatus,
      }),
    );
    final body = _decode(response);
    return Parcel.fromApi(body as Map<String, dynamic>);
  }

  dynamic _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Сервер вернул некорректный ответ (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'Ошибка API (${response.statusCode})';
    if (decoded is Map && decoded['detail'] != null) {
      final detail = decoded['detail'];
      message = detail is String ? detail : detail.toString();
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
