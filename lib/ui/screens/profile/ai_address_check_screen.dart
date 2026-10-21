import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AiAddressCheckScreen extends StatefulWidget {
  const AiAddressCheckScreen({super.key});

  @override
  State<AiAddressCheckScreen> createState() => _AiAddressCheckScreenState();
}

class _AiAddressCheckScreenState extends State<AiAddressCheckScreen> {
  final _controller = TextEditingController();
  String? _result;
  bool _ok = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check(AppProvider app) {
    final text = _controller.text.trim();
    final code = app.user?.clientCode ?? '';
    final s = app.strings;

    if (text.isEmpty) {
      setState(() {
        _ok = false;
        _result = s.isRu ? 'Вставьте адрес из карточки склада' : 'Суроғаро гузоред';
      });
      return;
    }

    final hasPhone = text.contains('13311198266');
    final hasRegion = text.contains('义乌') || text.contains('浙江');
    final hasClient = code.isNotEmpty && text.contains(code);

    if (hasPhone && hasRegion && hasClient) {
      setState(() {
        _ok = true;
        _result = s.isRu
            ? 'Адрес выглядит корректно. Телефон склада, регион и ваш код $code найдены.'
            : 'Суроға дуруст менамояд. Телефон, минтақа ва рамзи $code ёфт шуд.';
      });
    } else {
      final missing = <String>[];
      if (!hasPhone) missing.add(s.isRu ? 'телефон склада' : 'телефони анбор');
      if (!hasRegion) missing.add(s.isRu ? 'регион Иу' : 'минтақаи Иву');
      if (!hasClient) {
        missing.add(s.isRu ? 'ваш код $code' : 'рамзи шумо $code');
      }
      setState(() {
        _ok = false;
        _result = s.isRu
            ? 'Проверьте адрес. Не хватает: ${missing.join(', ')}.'
            : 'Суроғаро санҷед. Кам аст: ${missing.join(', ')}.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = app.strings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: cargoProfileAppBar(context, Text(s.aiAddressCheck)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SoftCard(
            child: Text(
              s.isRu
                  ? 'Как скинуть адрес (пошагово):\n'
                      '1) Главная → скопируйте адрес склада (кнопка «Копировать всё»).\n'
                      '2) Откройте Pinduoduo / 1688 / Taobao → «收货地址».\n'
                      '3) Получатель: ваш ID Cargo Line TJ, телефон 13311198266.\n'
                      '4) После заказа трек добавьте во вкладке «Заказы».\n\n'
                      'Ниже вставьте полный адрес — AI проверит телефон, регион и ваш код.'
                  : 'Суроғаро аз Асосӣ нусха кунед → дар маркетплейс гузоред → трекро ба Заказҳо илова кунед.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: s.isRu ? 'Вставьте адрес…' : 'Суроғаро гузоред…',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _check(app),
                    icon: const Icon(Icons.fact_check_rounded),
                    label: Text(s.isRu ? 'Проверить' : 'Санҷидан'),
                  ),
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            SoftCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _ok ? Icons.verified_rounded : Icons.warning_amber_rounded,
                    color: _ok ? CargoColors.success : CargoColors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _result!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _ok ? CargoColors.success : CargoColors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
