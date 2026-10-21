import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().strings;
    final p = context.watch<ParcelProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: cargoProfileAppBar(context, Text(s.statistics)),
      body: PullRefresh(
        onRefresh: () => context.read<ParcelProvider>().syncFromServer(),
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          SoftCard(
            child: Row(
              children: [
                Expanded(
                  child: _stat(
                    theme,
                    '${p.parcels.length}',
                    s.isRu ? 'Всего треков' : 'Ҳамаи трекҳо',
                  ),
                ),
                Expanded(
                  child: _stat(
                    theme,
                    '${p.countByStatus(ParcelStatusKey.inTransit)}',
                    s.isRu ? 'В пути' : 'Дар роҳ',
                  ),
                ),
                Expanded(
                  child: _stat(
                    theme,
                    '${p.countByStatus(ParcelStatusKey.received)}',
                    s.isRu ? 'Получено' : 'Гирифта шуд',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              children: ParcelStatusKey.values
                  .where((s) => s != ParcelStatusKey.pendingMatch)
                  .map((status) {
                final count = p.countByStatus(status);
                final total = p.parcels.isEmpty ? 1 : p.parcels.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.statusLabel(status),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text('$count', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: count / total,
                          minHeight: 6,
                          color: CargoColors.red,
                          backgroundColor: CargoColors.divider,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _stat(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 28,
            color: CargoColors.red,
          ),
        ),
        Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
