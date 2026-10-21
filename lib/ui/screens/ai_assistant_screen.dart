import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// AI Cargo — стабильная локальная проверка адреса склада.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AiAssistantScreen()),
    );
  }

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  String? _message;
  String? _corrected;
  bool _ok = false;
  final List<MapEntry<bool, String>> _checks = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _suffixOf(AppProvider app) {
    final u = app.user;
    if (u == null) return '';
    final s = u.warehouseSuffix.trim();
    if (s.isNotEmpty) return s;
    return u.clientCode.trim();
  }

  String _canonical(String suffix) {
    final tail = suffix.trim().isEmpty ? '' : ' ${suffix.trim()}';
    return '收货人：MA\n'
        '手机号码：${BrandConstants.warehousePhoneCn}\n'
        '所在地区：${BrandConstants.warehouseRegionCn}\n'
        '详细地址：${BrandConstants.warehouseStreetCn}$tail';
  }

  void _runCheck() {
    final app = context.read<AppProvider>();
    final isRu = app.strings.isRu;
    final text = _controller.text.trim();
    final suffix = _suffixOf(app);
    final code = (app.user?.clientCode ?? '').trim();
    final phone = BrandConstants.warehousePhoneCn;
    final corrected = _canonical(suffix.isNotEmpty ? suffix : code);

    if (text.isEmpty) {
      setState(() {
        _ok = false;
        _message = isRu
            ? 'Вставьте адрес склада в поле выше.'
            : 'Суроғаро дар майдон гузоред.';
        _corrected = corrected;
        _checks
          ..clear()
          ..add(MapEntry(false, isRu ? 'Текст адреса пуст' : 'Матн холӣ аст'));
      });
      return;
    }

    final digits = _digits(text);
    final hasPhone = digits.contains(phone) || text.contains(phone);
    final hasRegion = text.contains('义乌') ||
        text.contains('浙江') ||
        text.contains('金华') ||
        text.contains('义乌市');
    final id = suffix.isNotEmpty ? suffix : code;
    final hasId = id.isNotEmpty &&
        (text.contains(id) ||
            (code.isNotEmpty && text.contains(code)) ||
            RegExp(r'\(\d+\)').hasMatch(text));
    final hasMa =
        text.toUpperCase().contains('MA') || text.contains('收货人');

    final rows = <MapEntry<bool, String>>[
      MapEntry(hasMa, isRu ? '收货人 / имя: MA' : '收货人: MA'),
      MapEntry(hasPhone, isRu ? 'Телефон: $phone' : 'Телефон: $phone'),
      MapEntry(hasRegion, isRu ? 'Регион: 义乌 / 浙江' : 'Минтақа: 义乌'),
      MapEntry(
        hasId,
        isRu
            ? 'Ваш код в адресе: ${id.isEmpty ? "—" : id}'
            : 'Рамз: ${id.isEmpty ? "—" : id}',
      ),
    ];

    final ok = hasPhone && hasRegion && (hasId || id.isEmpty);
    setState(() {
      _ok = ok;
      _checks
        ..clear()
        ..addAll(rows);
      _corrected = corrected;
      _message = ok
          ? (isRu
              ? '✓ Адрес верный. Можно оформлять заказ.'
              : '✓ Суроға дуруст.')
          : (isRu
              ? '✗ Адрес неполный. Смотрите галочки и скопируйте готовый адрес ниже.'
              : '✗ Суроға нопурра. Суроғаи дурустро нусха кунед.');
    });
  }

  Future<void> _paste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final t = data?.text?.trim() ?? '';
      if (t.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Буфер пуст'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      setState(() {
        _controller.text = t;
        _message = null;
        _checks.clear();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось вставить'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _fillMine() {
    final app = context.read<AppProvider>();
    final suffix = _suffixOf(app);
    final code = (app.user?.clientCode ?? '').trim();
    final id = suffix.isNotEmpty ? suffix : code;
    setState(() {
      _controller.text = _canonical(id);
      _message = null;
      _checks.clear();
    });
  }

  Future<void> _copyCorrected() async {
    final t = _corrected;
    if (t == null || t.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: t));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Адрес скопирован'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().strings;
    final suffix = _suffixOf(context.watch<AppProvider>());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: cargoProfileAppBar(context, const Text('AI Cargo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5A6E), Color(0xFFE10600)],
                  ),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isRu
                          ? 'Проверка адреса склада'
                          : 'Санҷиши суроғаи анбор',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      s.isRu
                          ? 'Работает без интернета'
                          : 'Бе интернет кор мекунад',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (suffix.isNotEmpty)
                      Text(
                        'Код: $suffix',
                        style: const TextStyle(
                          color: Color(0xFFE10600),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            s.isRu
                ? 'Вставьте адрес из Pinduoduo / 1688 / Taobao или с главной.'
                : 'Суроғаро аз маркетплейс ё аз Асосӣ гузоред.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: '收货人：MA\n手机号码：13311198266\n...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: Text(s.isRu ? 'Буфер' : 'Буфер'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fillMine,
                  icon: const Icon(Icons.home_work_outlined, size: 18),
                  label: Text(s.isRu ? 'Мой адрес' : 'Суроға'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _runCheck,
              child: Text(s.isRu ? 'Проверить адрес' : 'Санҷидан'),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: TextStyle(
                color: _ok ? CargoColors.success : CargoColors.red,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
          if (_checks.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final c in _checks)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      c.key ? Icons.check_circle : Icons.cancel,
                      size: 20,
                      color: c.key ? CargoColors.success : CargoColors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.value)),
                  ],
                ),
              ),
          ],
          if (_corrected != null && _corrected!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              s.isRu ? 'Готовый правильный адрес' : 'Суроғаи дуруст',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CargoColors.red.withValues(alpha: 0.7)),
              ),
              child: SelectableText(
                _corrected!,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: _copyCorrected,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(s.isRu ? 'Скопировать' : 'Нусха'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
