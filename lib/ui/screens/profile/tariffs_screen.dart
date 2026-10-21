import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/services/content_api.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/material.dart';

class TariffsScreen extends StatefulWidget {
  const TariffsScreen({super.key});

  @override
  State<TariffsScreen> createState() => _TariffsScreenState();
}

class _TariffsScreenState extends State<TariffsScreen> {
  final _api = ContentApi();
  String _title = 'Стоимость доставки';
  List<(String, String)> _rows = const [
    ('1–20 кг', '25 сомони / кг'),
    ('20–30 кг', '24 сомони / кг'),
    ('30–40 кг', '23 сомони / кг'),
    ('40–80 кг', '22 сомони / кг'),
    ('80–120 кг', '21 сомони / кг'),
    ('120–150 кг', '20 сомони / кг'),
    ('150+ кг', 'договорная'),
    ('Малый объём, большой вес', 'от 0.67\$ / кг'),
  ];
  String _cityTitle = 'Доставка по городу';
  String _cityPrice = 'По городу 10 сомони';
  String _cityNote = 'Выше 5 кг — бесплатно';
  String _footnote =
      'Если куб маленький, но товар тяжёлый — считаем от 0.67\$ за кг. '
      'Точный расчёт можно сделать в калькуляторе профиля.';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.tariffs();
      final rows = <(String, String)>[];
      final raw = data['rows'];
      if (raw is List) {
        for (final e in raw) {
          if (e is! Map) continue;
          final label = (e['label'] as String? ?? '').trim();
          final value = (e['value'] as String? ?? '').trim();
          if (label.isEmpty && value.isEmpty) continue;
          rows.add((label, value));
        }
      }
      if (!mounted) return;
      setState(() {
        final title = (data['title'] as String?)?.trim();
        if (title != null && title.isNotEmpty) _title = title;
        if (rows.isNotEmpty) _rows = rows;
        _cityTitle = (data['city_title'] as String?)?.trim() ?? _cityTitle;
        _cityPrice = (data['city_price'] as String?)?.trim() ?? _cityPrice;
        _cityNote = (data['city_note'] as String?)?.trim() ?? _cityNote;
        final foot = (data['footnote'] as String?)?.trim();
        if (foot != null && foot.isNotEmpty) _footnote = foot;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: cargoProfileAppBar(context, const Text('Тарифы')),
      body: PullRefresh(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  ..._rows.map((t) => _row(theme, t.$1, t.$2)),
                ],
              ),
            ),
            if (_cityTitle.isNotEmpty || _cityPrice.isNotEmpty) ...[
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_cityTitle.isNotEmpty)
                      Text(_cityTitle, style: theme.textTheme.titleLarge),
                    if (_cityPrice.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _cityPrice,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: CargoColors.red),
                      ),
                    ],
                    if (_cityNote.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _cityNote,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: CargoColors.success),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_footnote.isNotEmpty) ...[
              const SizedBox(height: 12),
              SoftCard(
                child: Text(_footnote, style: theme.textTheme.bodyLarge),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String left, String right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(left, style: theme.textTheme.titleMedium)),
          Text(
            right,
            style: theme.textTheme.titleMedium?.copyWith(color: CargoColors.red),
          ),
        ],
      ),
    );
  }
}
