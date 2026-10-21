import 'dart:async';
import 'dart:convert';

import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<_Msg> _messages = [];
  bool _sending = false;
  bool _loading = true;
  Timer? _pollTimer;

  static const _cacheKey = 'support_messages_v1';
  static const _cacheTtl = Duration(hours: 20);

  static final _welcome = _Msg(
    id: 0,
    text:
        'Ас Саламу Алейкум! Вас приветствует компания Cargo Line TJ. '
        'Напишите вопрос — ответим в ближайшее время.',
    fromAdmin: true,
    readByAdmin: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadCachedMessages();
      await _fetchMessages();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _fetchMessages(),
      );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  List<_Msg> _withinTtl(Iterable<_Msg> items) {
    final cutoff = DateTime.now().subtract(_cacheTtl);
    return items.where((m) => m.savedAt.isAfter(cutoff)).toList();
  }

  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list.map((e) {
        final m = e as Map<String, dynamic>;
        return _Msg(
          id: m['id'] as int? ?? 0,
          text: m['text'] as String? ?? '',
          fromAdmin: m['fromAdmin'] as bool? ?? false,
          readByAdmin: m['readByAdmin'] as bool? ?? false,
          savedAt: DateTime.fromMillisecondsSinceEpoch(
            m['savedAtMs'] as int? ?? 0,
          ),
        );
      }).toList();
      final fresh = _withinTtl(parsed);
      if (!mounted || fresh.isEmpty) return;
      setState(() {
        _loading = false;
        _messages = _withWelcome(fresh);
      });
      _scrollToEnd();
    } catch (_) {}
  }

  Future<void> _persistMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fresh = _withinTtl(_messages.where((m) => m.id != 0));
      final payload = fresh
          .map(
            (m) => {
              'id': m.id,
              'text': m.text,
              'fromAdmin': m.fromAdmin,
              'readByAdmin': m.readByAdmin,
              'savedAtMs': m.savedAt.millisecondsSinceEpoch,
            },
          )
          .toList();
      await prefs.setString(_cacheKey, jsonEncode(payload));
    } catch (_) {}
  }

  List<_Msg> _withWelcome(List<_Msg> items) {
    if (items.isEmpty) return [_welcome];
    final hasWelcome = items.any((m) => m.id == 0 && m.fromAdmin);
    if (hasWelcome) return items;
    return [_welcome, ...items];
  }

  List<_Msg> _mergeMessages(List<_Msg> remote, List<_Msg> local) {
    final byId = <int, _Msg>{};
    for (final m in local) {
      if (m.id != 0) byId[m.id] = m;
    }
    for (final m in remote) {
      byId[m.id] = m;
    }
    // Drop optimistic (negative id) duplicates once server copy exists.
    final serverTexts = byId.values
        .where((m) => m.id > 0 && !m.fromAdmin)
        .map((m) => m.text.trim())
        .toSet();
    byId.removeWhere(
      (id, m) => id < 0 && !m.fromAdmin && serverTexts.contains(m.text.trim()),
    );
    final merged = byId.values.toList()
      ..sort((a, b) {
        final c = a.savedAt.compareTo(b.savedAt);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
    // Never TTL-drop server messages — only cache cleanup uses TTL.
    return _withWelcome(merged);
  }

  Future<void> _fetchMessages() async {
    final app = context.read<AppProvider>();
    var token = app.accessToken;
    if (token == null || token.isEmpty) {
      if (mounted && _loading && _messages.isEmpty) {
        setState(() {
          _loading = false;
          _messages = [_welcome];
        });
      }
      return;
    }
    try {
      final res = await http
          .get(
            Uri.parse('${AuthService.defaultBaseUrl}/api/v1/support/messages'),
            headers: _headers(token),
          )
          .timeout(AuthService.requestTimeout);
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final now = DateTime.now();
        final parsed = list.map((e) {
          final m = e as Map<String, dynamic>;
          final sender = m['sender'] as String? ?? 'client';
          DateTime saved = now;
          final rawAt = m['created_at'] as String?;
          if (rawAt != null && rawAt.isNotEmpty) {
            saved = DateTime.tryParse(rawAt) ?? now;
          }
          return _Msg(
            id: m['id'] as int? ?? 0,
            text: m['text'] as String? ?? '',
            fromAdmin: sender == 'admin',
            readByAdmin: m['read_by_admin'] as bool? ?? false,
            savedAt: saved,
          );
        }).toList();
        setState(() {
          _loading = false;
          _messages = parsed.isEmpty
              ? (_messages.isEmpty ? [_welcome] : _messages)
              : _mergeMessages(parsed, _messages);
        });
        await _persistMessages();
        _scrollToEnd();
      } else if (_loading && _messages.isEmpty) {
        setState(() {
          _loading = false;
          _messages = [_welcome];
        });
      }
    } catch (_) {
      if (mounted && _loading && _messages.isEmpty) {
        setState(() {
          _loading = false;
          _messages = [_welcome];
        });
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _requestOperator() async {
    final token = context.read<AppProvider>().accessToken;
    if (token == null) return;
    try {
      await http
          .post(
            Uri.parse('${AuthService.defaultBaseUrl}/api/v1/support/send'),
            headers: _headers(token),
            body: jsonEncode({
              'text': '🔔 Клиент запросил оператора Cargo Line TJ',
            }),
          )
          .timeout(AuthService.requestTimeout);
      await _fetchMessages();
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final now = DateTime.now();
    final tempId = -now.millisecondsSinceEpoch;
    setState(() {
      _sending = true;
      _messages = [
        ..._messages.where((m) => m.id != 0 || m.fromAdmin),
        _Msg(
          id: tempId,
          text: text,
          fromAdmin: false,
          readByAdmin: false,
          savedAt: now,
        ),
      ];
    });
    await _persistMessages();
    _ctrl.clear();
    _scrollToEnd();
    final token = context.read<AppProvider>().accessToken;
    try {
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нет сессии — войдите снова, чтобы писать в чат'),
            ),
          );
        }
        return;
      }
      final res = await http
          .post(
            Uri.parse('${AuthService.defaultBaseUrl}/api/v1/support/send'),
            headers: _headers(token),
            body: jsonEncode({'text': text}),
          )
          .timeout(AuthService.requestTimeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final serverId = body['id'] as int?;
        if (serverId != null && mounted) {
          setState(() {
            _messages = _messages
                .map(
                  (m) => m.id == tempId
                      ? _Msg(
                          id: serverId,
                          text: m.text,
                          fromAdmin: false,
                          readByAdmin: m.readByAdmin,
                          savedAt: m.savedAt,
                        )
                      : m,
                )
                .toList();
          });
          await _persistMessages();
        }
        await _fetchMessages();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не отправлено (${res.statusCode}). Проверьте Wi‑Fi и сервер.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Нет связи с сервером — сообщение пока только на телефоне',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const adminBubble = Color(0xFF0072FF);
    const adminBubbleDark = Color(0xFF4DA3FF);

    return Scaffold(
      appBar: cargoProfileAppBar(context, const Text('Техподдержка')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SoftCard(
              child: Column(
                children: [
                  const CargoIcon(
                    asset: CargoIconAssets.supportChat,
                    icon: Icons.support_agent,
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _requestOperator,
                      icon: const Icon(Icons.support_agent_rounded),
                      label: const Text('Вызвать оператора (в приложении)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            BrandConstants.telegramAdmin(),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Telegram'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            BrandConstants.whatsAppAdmin(),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : PullRefresh(
                    onRefresh: _fetchMessages,
                    child: ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final align = m.fromAdmin
                          ? Alignment.centerLeft
                          : Alignment.centerRight;
                      final bubbleColor = m.fromAdmin
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? adminBubbleDark
                              : adminBubble)
                          : CargoColors.red;
                      return Align(
                        alignment: align,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                m.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              if (!m.fromAdmin) ...[
                                const SizedBox(height: 4),
                                Icon(
                                  m.readByAdmin
                                      ? Icons.done_all
                                      : Icons.done,
                                  size: 16,
                                  color: m.readByAdmin
                                      ? const Color(0xFFB3E5FC)
                                      : Colors.white70,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Сообщение…',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded, color: CargoColors.accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  _Msg({
    required this.id,
    required this.text,
    required this.fromAdmin,
    required this.readByAdmin,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  final int id;
  final String text;
  final bool fromAdmin;
  final bool readByAdmin;
  final DateTime savedAt;
}
