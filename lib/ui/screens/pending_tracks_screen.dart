import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pending track codes (not yet matched by admin).
class PendingTracksScreen extends StatelessWidget {
  const PendingTracksScreen({super.key});

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy · $hh:$min';
  }

  Future<void> _delete(BuildContext context, String id) async {
    await context.read<ParcelProvider>().deleteById(id);
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<ParcelProvider>().pendingParcels;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваши треккоды'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: CargoColors.red,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PullRefresh(
        onRefresh: () => context.read<ParcelProvider>().syncFromServer(),
        child: pending.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    'Нет ожидающих трек-кодов',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = pending[i];
                return SoftCard(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              p.trackCode,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Добавлен: ${_fmtDate(p.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Удалить',
                        onPressed: () => _delete(context, p.id),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: CargoColors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
