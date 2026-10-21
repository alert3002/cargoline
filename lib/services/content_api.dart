import 'dart:convert';

import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:http/http.dart' as http;

class ChinaAddress {
  const ChinaAddress({
    required this.id,
    required this.name,
    required this.recipient,
    required this.phone,
    required this.region,
    required this.detail,
    this.notes = '',
  });

  final int id;
  final String name;
  final String recipient;
  final String phone;
  final String region;
  final String detail;
  final String notes;

  factory ChinaAddress.fromJson(Map<String, dynamic> json) {
    return ChinaAddress(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      recipient: (json['contact'] as String? ?? '').trim(),
      phone: (json['phone'] as String? ?? '').trim(),
      region: (json['region'] as String? ?? '').trim(),
      detail: (json['address'] as String? ?? '').trim(),
      notes: (json['notes'] as String? ?? '').trim(),
    );
  }
}

class ContentApi {
  ContentApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AuthService.defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  Future<List<ChinaAddress>> warehouses() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/v1/warehouses'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('warehouses ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ChinaAddress.fromJson(e as Map<String, dynamic>))
        .where((a) => a.detail.isNotEmpty || a.name.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> deliveryTerms() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/v1/content/delivery-terms'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('terms ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> tariffs() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/v1/content/tariffs'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('tariffs ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
