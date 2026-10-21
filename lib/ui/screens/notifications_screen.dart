import 'dart:convert';

import 'package:cargo_line_tj/core/media_url.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  static const _dismissKey = 'dismissed_news_ids';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Set<int>> _localDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_dismissKey) ?? const <String>[];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _saveLocalDismissed(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dismissKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AppProvider>().accessToken;
    final localGone = await _localDismissed();
    try {
      if (token != null) {
        final res = await http
            .get(
              Uri.parse('${AuthService.defaultBaseUrl}/api/v1/notifications'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(AuthService.requestTimeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final list = jsonDecode(res.body) as List<dynamic>;
          _items = list
              .cast<Map<String, dynamic>>()
              .where((n) {
                final id = n['id'] as int? ?? 0;
                return id > 0 && !localGone.contains(id);
              })
              .toList();
          await http.post(
            Uri.parse('${AuthService.defaultBaseUrl}/api/v1/notifications/read'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (mounted) {
            context.read<AppProvider>().setUnreadNotifications(0);
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    final token = context.read<AppProvider>().accessToken;
    setState(() => _items.removeWhere((n) => n['id'] == id));
    final gone = await _localDismissed()..add(id);
    await _saveLocalDismissed(gone);
    if (token != null) {
      try {
        await http
            .delete(
              Uri.parse(
                '${AuthService.defaultBaseUrl}/api/v1/notifications/$id',
              ),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(AuthService.requestTimeout);
      } catch (_) {}
    }
  }

  Widget _image(String? raw) {
    final url = resolveMediaUrl(raw);
    if (url == null) return const SizedBox.shrink();
    if (url.startsWith('data:')) {
      try {
        final b64 = url.split(',').last;
        final bytes = base64Decode(b64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 180,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  String _when(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}, ${two(dt.hour)}:${two(dt.minute)}';
  }

  IconData _iconFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('статус') || t.contains('груз')) {
      return Icons.local_shipping_rounded;
    }
    if (t.contains('сообщ')) return Icons.chat_bubble_rounded;
    return Icons.campaign_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Новости и сообщения')),
      body: _loading && _items.isEmpty
          ? const Center(child: CupertinoActivityIndicator())
          : PullRefresh(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Пока нет уведомлений')),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final n = _items[i];
                        final id = n['id'] as int? ?? 0;
                        final title = n['title']?.toString() ?? '';
                        final body = n['body']?.toString() ??
                            n['text']?.toString() ??
                            '';
                        final image = n['image_url']?.toString();
                        final when = _when(n['created_at']?.toString());
                        return Dismissible(
                          key: ValueKey('news_$id'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: CargoColors.red.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _delete(id),
                          child: SoftCard(
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: CargoColors.red.withValues(
                                          alpha: isDark ? 0.18 : 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _iconFor(title),
                                        color: CargoColors.red,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          if (when.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.schedule_rounded,
                                                  size: 13,
                                                  color: isDark
                                                      ? CargoColors.darkMuted
                                                      : CargoColors.lightMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  when,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? CargoColors.darkMuted
                                                        : CargoColors
                                                            .lightMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Удалить',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _delete(id),
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: CargoColors.red.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (image != null && image.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _image(image),
                                ],
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      body,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.92,
                                              )
                                            : CargoColors.lightText,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
