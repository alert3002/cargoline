import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/services/content_api.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryTermsScreen extends StatefulWidget {
  const DeliveryTermsScreen({super.key});

  @override
  State<DeliveryTermsScreen> createState() => _DeliveryTermsScreenState();
}

class _DeliveryTermsScreenState extends State<DeliveryTermsScreen> {
  final _api = ContentApi();
  String _intro =
      'Сроки ориентировочные и зависят от сезона, таможни и загрузки склада.';
  List<(String, String)> _items = const [
    ('Общий срок', 'от 12 до 20 дней с момента получения товара на наш склад в Китае'),
    ('Склад Китай', '1–3 дня после сканирования трек-кода на складе'),
    ('В пути', 'автоматически через 3 дня после статуса «На складе в Китае»'),
    ('Склад Таджикистан', 'Худжанд 19 мкр — после массового обновления в админке'),
    ('Доставка', 'оформление через WhatsApp +992 92 627 7667'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.deliveryTerms();
      final intro = (data['intro'] as String?)?.trim();
      final raw = data['items'];
      final items = <(String, String)>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is! Map) continue;
          final title = (e['title'] as String? ?? '').trim();
          final body = (e['body'] as String? ?? '').trim();
          if (title.isEmpty && body.isEmpty) continue;
          items.add((title, body));
        }
      }
      if (!mounted) return;
      setState(() {
        if (intro != null && intro.isNotEmpty) _intro = intro;
        if (items.isNotEmpty) _items = items;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().strings;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: cargoProfileAppBar(context, Text(s.deliveryTerms)),
      body: PullRefresh(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            SoftCard(child: Text(_intro, style: theme.textTheme.bodyLarge)),
            const SizedBox(height: 12),
            ..._items.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: CargoColors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.$1.isNotEmpty)
                              Text(e.$1, style: theme.textTheme.titleMedium),
                            if (e.$2.isNotEmpty)
                              Text(e.$2, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
