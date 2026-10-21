import 'dart:convert';

import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:cargo_line_tj/core/media_url.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/cart_provider.dart';
import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<MarketItem> _products = [];
  List<MarketItem> _filtered = [];
  bool _loading = false;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http
          .get(Uri.parse('${AuthService.defaultBaseUrl}/api/v1/market'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = jsonDecode(res.body) as List<dynamic>;
        _products = list.map((e) {
          final m = e as Map<String, dynamic>;
          return MarketItem(
            id: m['id'] as int,
            title: m['title'] as String? ?? '',
            description: m['description'] as String? ?? '',
            price: (m['price'] as num?)?.toDouble() ?? 0,
            imageUrl: resolveMediaUrl(m['image_url'] as String?),
          );
        }).toList();
      } else {
        // Keep previous list on error (offline-friendly).
      }
    } catch (_) {
      // Keep previous / empty — no demo catalog.
    }
    _applyFilter(_search.text);
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter(String q) {
    final qq = q.trim().toLowerCase();
    _filtered = qq.isEmpty
        ? List.from(_products)
        : _products
            .where((p) =>
                p.title.toLowerCase().contains(qq) ||
                p.description.toLowerCase().contains(qq))
            .toList();
  }

  Future<void> _checkout(CartProvider cart) async {
    if (cart.totalCount == 0) return;
    final msg = Uri.encodeComponent(cart.orderMessage());
    final wa =
        Uri.parse('https://wa.me/${BrandConstants.deliveryPhone}?text=$msg');
    await launchUrl(wa, mode: LaunchMode.externalApplication);
  }

  void _openCart() {
    final rootCtx = context;
    showModalBottomSheet<void>(
      context: rootCtx,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Theme.of(rootCtx).brightness == Brightness.dark
          ? const Color(0xFF2C161A)
          : const Color(0xFFFFF6F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Consumer<CartProvider>(
            builder: (context, cart, _) {
              final h = MediaQuery.sizeOf(context).height * 0.72;
              return SizedBox(
                height: h,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Корзина (${cart.totalCount})',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Expanded(
                        child: cart.items.isEmpty
                            ? const Center(child: Text('Корзина пуста'))
                            : ListView.separated(
                                itemCount: cart.items.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final item = cart.items[i];
                                  final q = cart.quantities[item.id] ?? 1;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: _Thumb(url: item.imageUrl),
                                    title: Text(item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: Text(
                                        '${item.price.toStringAsFixed(0)} TJS × $q'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              cart.setQty(item.id, q - 1),
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
                                        ),
                                        Text('$q'),
                                        IconButton(
                                          onPressed: () =>
                                              cart.setQty(item.id, q + 1),
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              cart.remove(item.id),
                                          icon: const Icon(
                                              Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: cart.clear,
                            child: const Text('Очистить'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: cart.totalCount == 0
                                ? null
                                : () {
                                    Navigator.pop(sheetCtx);
                                    _checkout(cart);
                                  },
                            child: const Text('Оформить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openDetail(MarketItem p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _MarketDetailPage(item: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Text(
                    'Маркет',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: _openCart,
                        icon: Icon(
                          Icons.shopping_bag_outlined,
                          size: 26,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (cart.totalCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: CargoColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cart.totalCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Поиск товаров…',
                  prefixIcon: Icon(Icons.search, color: CargoColors.accent),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _applyFilter(v)),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : RefreshIndicator(
                      color: CargoColors.red,
                      onRefresh: _load,
                      child: _filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Товаров пока нет.\nДобавьте в админке → Маркет.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 110),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.74,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final p = _filtered[i];
                          return SoftCard(
                            onTap: () => _openDetail(p),
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: _Thumb(url: p.imageUrl, big: true),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 6, 8, 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          height: 1.2,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${p.price.toStringAsFixed(0)} TJS',
                                        style: const TextStyle(
                                          color: CargoColors.accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 32,
                                        child: FilledButton(
                                          onPressed: () {
                                            cart.add(p);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text('В корзине'),
                                                duration:
                                                    Duration(milliseconds: 900),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          child: const Icon(
                                            Icons.add_shopping_cart_rounded,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url, this.big = false});
  final String? url;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(url);
    if (resolved == null || resolved.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFFFE0E4),
        child: Icon(
          Icons.shopping_bag_outlined,
          size: big ? 48 : 28,
          color: CargoColors.accent,
        ),
      );
    }
    if (resolved.startsWith('data:')) {
      try {
        final bytes = base64Decode(resolved.split(',').last);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: big ? double.infinity : 52,
          height: big ? double.infinity : 52,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFFFE0E4),
            child: Icon(Icons.image, color: CargoColors.accent),
          ),
        );
      } catch (_) {
        return const ColoredBox(
          color: Color(0xFFFFE0E4),
          child: Icon(Icons.image, color: CargoColors.accent),
        );
      }
    }
    return Image.network(
      resolved,
      fit: BoxFit.cover,
      width: big ? double.infinity : 52,
      height: big ? double.infinity : 52,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFFFE0E4),
        child: Icon(Icons.image, color: CargoColors.accent),
      ),
      loadingBuilder: (c, child, p) {
        if (p == null) return child;
        return const ColoredBox(
          color: Color(0xFFFFE8EB),
          child: Center(child: CupertinoActivityIndicator()),
        );
      },
    );
  }
}

class _MarketDetailPage extends StatelessWidget {
  const _MarketDetailPage({required this.item});

  final MarketItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(item.title, maxLines: 1)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: _Thumb(url: item.imageUrl, big: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.price.toStringAsFixed(0)} TJS',
            style: const TextStyle(
              color: CargoColors.accent,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.4,
                  color: isDark ? Colors.white : Colors.black87,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              cart.add(item);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Добавлено в корзину'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Добавить в корзину'),
          ),
        ],
      ),
    );
  }
}
