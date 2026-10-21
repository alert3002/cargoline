import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarketItem {
  const MarketItem({
    required this.id,
    required this.title,
    required this.price,
    this.description = '',
    this.imageUrl,
  });

  final int id;
  final String title;
  final double price;
  final String description;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
      };

  factory MarketItem.fromJson(Map<String, dynamic> json) => MarketItem(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
      );
}

class CartProvider extends ChangeNotifier {
  CartProvider() {
    _load();
  }

  static const _kCart = 'market_cart_json_v1';

  final Map<int, int> _qty = {};
  final Map<int, MarketItem> _items = {};
  bool _ready = false;

  bool get ready => _ready;
  Map<int, int> get quantities => Map.unmodifiable(_qty);
  List<MarketItem> get items =>
      _qty.keys.map((id) => _items[id]!).toList(growable: false);
  int get totalCount => _qty.values.fold(0, (a, b) => a + b);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCart);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final items = (map['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        final qtys = (map['qty'] as Map<String, dynamic>? ?? const {});
        for (final e in items) {
          final item = MarketItem.fromJson(e);
          final q = (qtys['${item.id}'] as num?)?.toInt() ?? 0;
          if (q > 0) {
            _items[item.id] = item;
            _qty[item.id] = q;
          }
        }
      }
    } catch (_) {}
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kCart,
        jsonEncode({
          'items': _items.values.map((e) => e.toJson()).toList(),
          'qty': {for (final e in _qty.entries) '${e.key}': e.value},
        }),
      );
    } catch (_) {}
  }

  void add(MarketItem item) {
    _items[item.id] = item;
    _qty[item.id] = (_qty[item.id] ?? 0) + 1;
    notifyListeners();
    _persist();
  }

  void setQty(int id, int qty) {
    if (qty <= 0) {
      _qty.remove(id);
      _items.remove(id);
    } else {
      _qty[id] = qty;
    }
    notifyListeners();
    _persist();
  }

  void remove(int id) {
    _qty.remove(id);
    _items.remove(id);
    notifyListeners();
    _persist();
  }

  void clear() {
    _qty.clear();
    _items.clear();
    notifyListeners();
    _persist();
  }

  String orderMessage() {
    final buf = StringBuffer(
      'Ас Саламу Алейкум, меня интересует такой товар:\n',
    );
    for (final id in _qty.keys) {
      final item = _items[id]!;
      final q = _qty[id]!;
      buf.writeln('• ${item.title} × $q (${item.price} TJS)');
    }
    return buf.toString().trim();
  }
}
