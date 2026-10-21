import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _weight = TextEditingController();
  final _cube = TextEditingController();
  String? _kgResult;
  String? _cubeResult;

  static const _cubeRateUsd = 260.0;

  void _calcKg() {
    final w = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    if (w == null || w <= 0) {
      setState(() => _kgResult = null);
      return;
    }
    final rate = w <= 30 ? 25.0 : 24.5;
    final somoni = w * rate;
    final heavyUsd = w * 0.67;
    setState(() {
      _kgResult =
          'По весу: ${somoni.toStringAsFixed(2)} сомони\n'
          'Тяжёлый тариф: \$${heavyUsd.toStringAsFixed(2)} (от 0.67\$/кг)';
    });
  }

  void _calcCube() {
    final c = double.tryParse(_cube.text.trim().replaceAll(',', '.'));
    if (c == null || c <= 0) {
      setState(() => _cubeResult = null);
      return;
    }
    final usd = c * _cubeRateUsd;
    setState(() {
      _cubeResult =
          'Объём: ${c.toStringAsFixed(2)} м³\n'
          'Итого: \$${usd.toStringAsFixed(2)} (по $_cubeRateUsd\$ / м³)';
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _cube.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: cargoProfileAppBar(context, const Text('Калькулятор')),
      body: PullRefresh(
        onRefresh: () async {},
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.scale_rounded, color: CargoColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Расчёт по кг',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Вес, кг',
                    prefixIcon: Icon(Icons.monitor_weight_outlined,
                        color: CargoColors.accent),
                  ),
                  onChanged: (_) => _calcKg(),
                ),
                if (_kgResult != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _kgResult!,
                    style: const TextStyle(
                      color: CargoColors.accent,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.view_in_ar_rounded, color: CargoColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Расчёт по кубу',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Тариф: $_cubeRateUsd \$ за 1 м³',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cube,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Объём, м³ (куб)',
                    prefixIcon:
                        Icon(Icons.view_in_ar_outlined, color: CargoColors.accent),
                  ),
                  onChanged: (_) => _calcCube(),
                ),
                if (_cubeResult != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _cubeResult!,
                    style: const TextStyle(
                      color: CargoColors.accent,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
