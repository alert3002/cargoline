import 'dart:ui';

import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/models/parcel.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:cargo_line_tj/ui/widgets/empty_state.dart';
import 'package:cargo_line_tj/ui/widgets/parcel_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key, required this.status});

  final ParcelStatusKey status;

  bool get _isDeliveryFlow =>
      status == ParcelStatusKey.delivery ||
      status == ParcelStatusKey.tajikistanWarehouse;

  Future<void> _wa(String text) async {
    final uri = Uri.parse(
      'https://wa.me/${BrandConstants.deliveryPhone}?text=${Uri.encodeComponent(text)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _tracksLine(List<Parcel> parcels) =>
      parcels.map((p) => p.trackCode).join(', ');

  Future<void> _openBank(BuildContext context, String key) async {
    for (final scheme in BrandConstants.bankPaymentUris(key)) {
      try {
        final ok = await launchUrl(
          Uri.parse(scheme),
          mode: LaunchMode.externalApplication,
        );
        if (ok) return;
      } catch (_) {}
    }

    final pkg = BrandConstants.bankPackages[key];
    if (pkg != null && Theme.of(context).platform == TargetPlatform.android) {
      try {
        final ok = await launchUrl(
          Uri.parse(
            'intent://pay/#Intent;scheme=https;package=$pkg;end',
          ),
          mode: LaunchMode.externalApplication,
        );
        if (ok) return;
      } catch (_) {}
    }

    final store = Theme.of(context).platform == TargetPlatform.iOS
        ? (BrandConstants.bankIosStoreUrls[key] ??
            BrandConstants.bankStoreUrls[key])
        : BrandConstants.bankStoreUrls[key];
    if (store != null) {
      await launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication);
    }
  }

  void _showDeliveryMenuSheet(
    BuildContext context, {
    required AppStrings s,
    required ParcelProvider provider,
    required List<Parcel> parcels,
    required String name,
    required String code,
  }) {
    final tracks = parcels.map((p) => p.trackCode).toList();
    final tracksLine = _tracksLine(parcels);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.5;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetTheme = Theme.of(ctx);
        final isDark = sheetTheme.brightness == Brightness.dark;
        final onSheet = isDark ? Colors.white : Colors.black87;
        final onSheetMuted = isDark
            ? Colors.white.withValues(alpha: 0.92)
            : Colors.black.withValues(alpha: 0.72);
        final frostFill = isDark
            ? const Color(0xE6101012)
            : const Color(0xE6FAFAFA);
        final handleColor = isDark
            ? Colors.white.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.22);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: sheetHeight,
              decoration: BoxDecoration(
                color: frostFill,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: handleColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        s.isRu ? 'Оплата и доставка' : 'Пардохт ва расонидан',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSheet,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _BankTile(
                            asset: CargoIconAssets.bankDushanbe,
                            label: 'Dushanbe City',
                            onTap: () => _openBank(ctx, 'dushanbe'),
                          ),
                          _BankTile(
                            asset: CargoIconAssets.bankEskhata,
                            label: 'Eskhata',
                            onTap: () => _openBank(ctx, 'eskhata'),
                          ),
                          _BankTile(
                            asset: CargoIconAssets.bankAlif,
                            label: 'Alif',
                            onTap: () => _openBank(ctx, 'alif'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        s.isRu
                            ? 'Перевод на ДС ${BrandConstants.dcWallet} · отправьте скрин → админу'
                            : 'Ба ДС ${BrandConstants.dcWallet} · скрин → ба админ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSheetMuted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: CargoColors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await provider.updateFulfillmentMode(
                                  'delivery',
                                  trackCodes: tracks,
                                );
                                await _wa(
                                  'Ас Саламу Алейкум! $name ($code)\n'
                                  'Заказать доставку по Худжанду (${BrandConstants.cityDeliverySomoni} сомони).\n'
                                  'Трек-коды: $tracksLine\n'
                                  'ДС: ${BrandConstants.dcWallet}',
                                );
                              },
                              child: Text(
                                s.isRu ? 'Заказать доставку' : 'Расонидан',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: onSheet,
                                side: BorderSide(
                                  color: onSheet.withValues(alpha: 0.45),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await provider.updateFulfillmentMode(
                                  'pickup',
                                  trackCodes: tracks,
                                );
                                await _wa(
                                  'Ас Саламу Алейкум! $name ($code)\n'
                                  'Самовывоз: сам заеду за своими товарами.\n'
                                  'Трек-коды: $tracksLine',
                                );
                              },
                              child: Text(
                                s.isRu ? 'Самовывоз' : 'Худ мегирам',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: onSheet,
                                side: BorderSide(
                                  color: onSheet.withValues(alpha: 0.35),
                                ),
                              ),
                              onPressed: () async {
                                await provider.updatePaymentMethod(
                                  'cash',
                                  trackCodes: tracks,
                                );
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        s.isRu
                                            ? 'Отмечено: оплата наличными'
                                            : 'Пардохти нақд',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                s.isRu ? 'Оплатил наличными' : 'Пардохти нақд',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: onSheet,
                                side: BorderSide(
                                  color: onSheet.withValues(alpha: 0.35),
                                ),
                              ),
                              onPressed: () async {
                                await provider.updatePaymentMethod(
                                  'cashless',
                                  trackCodes: tracks,
                                );
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        s.isRu
                                            ? 'Отмечено: безнал'
                                            : 'Бе нақд',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Text(s.isRu ? 'Безнал' : 'Бе нақд'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmReceivedAll(
    BuildContext context, {
    required AppStrings s,
    required ParcelProvider provider,
    required List<Parcel> parcels,
    required String name,
    required String code,
  }) async {
    if (parcels.isEmpty) return;
    final tracks = _tracksLine(parcels);
    await _wa(
      'Ас Саламу Алейкум! $name ($code)\n'
      'Получил все посылки.\n'
      'Трек-коды: $tracks',
    );
    await provider.markManyReceived(parcels.map((p) => p.trackCode));
    await provider.deleteReceived();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isRu ? 'Спасибо! Треки удалены из списка' : 'Трекҳо нест шуданд',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmReceivedPartial(
    BuildContext context, {
    required AppStrings s,
    required ParcelProvider provider,
    required List<Parcel> parcels,
    required String name,
    required String code,
  }) async {
    final selected = parcels
        .where((p) => provider.selectedIds.contains(p.id))
        .toList();
    if (selected.isEmpty) return;
    final tracks = _tracksLine(selected);
    await _wa(
      'Ас Саламу Алейкум! $name ($code)\n'
      'Получил частично.\n'
      'Трек-коды: $tracks',
    );
    await provider.markManyReceived(selected.map((p) => p.trackCode));
    await provider.deleteSelected();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isRu ? 'Выбранные треки удалены' : 'Трекҳои интихобшуда нест шуданд',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = app.strings;
    final provider = context.watch<ParcelProvider>();
    final parcels = provider.byStatus(status);
    final selecting = provider.selectionMode;
    final name = app.user?.name ?? 'Клиент';
    final code = app.user?.clientCode ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.statusLabel(status)),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: CargoColors.accent,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isDeliveryFlow && parcels.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              color: CargoColors.accent,
              tooltip: s.isRu ? 'Оплата и доставка' : 'Меню',
              onPressed: () => _showDeliveryMenuSheet(
                context,
                s: s,
                provider: provider,
                parcels: parcels,
                name: name,
                code: code,
              ),
            ),
          if (status == ParcelStatusKey.received) ...[
            TextButton(
              onPressed: () {
                if (selecting) {
                  provider.toggleSelectionMode(false);
                } else {
                  provider.selectAllReceived();
                }
              },
              child: Text(
                selecting
                    ? (s.isRu ? 'Отмена' : 'Бекор')
                    : (s.isRu ? 'Выбрать' : 'Интихоб'),
              ),
            ),
          ],
        ],
      ),
      body: PullRefresh(
        onRefresh: () => context.read<ParcelProvider>().syncFromServer(),
        child: parcels.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 40),
                EmptyState(
                  icon: Icons.inventory_2_outlined,
                  iconAsset: CargoIconAssets.navOrders,
                  title: s.noOrders,
                  subtitle: s.isRu
                      ? 'В статусе «${s.statusLabel(status)}» пока нет посылок'
                      : 'Дар статуси «${s.statusLabel(status)}» ҳанӯз бор нест',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                _isDeliveryFlow && parcels.isNotEmpty ? 120 : 100,
              ),
              itemCount: parcels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = parcels[i];
                final selected = provider.selectedIds.contains(p.id);
                final canSelect = status == ParcelStatusKey.received ||
                    (_isDeliveryFlow && selecting);
                return ParcelCard(
                  parcel: p,
                  selectable: canSelect,
                  selected: selected,
                  onLongPress: status == ParcelStatusKey.received ||
                          _isDeliveryFlow
                      ? () {
                          provider.toggleSelectionMode(true);
                          provider.toggleSelect(p.id);
                        }
                      : null,
                  onTap: () {
                    if (canSelect && selecting) {
                      provider.toggleSelect(p.id);
                    }
                  },
                );
              },
            ),
      ),
      bottomNavigationBar: _bottomBar(
        context,
        s: s,
        provider: provider,
        parcels: parcels,
        selecting: selecting,
        name: name,
        code: code,
      ),
    );
  }

  Widget? _bottomBar(
    BuildContext context, {
    required AppStrings s,
    required ParcelProvider provider,
    required List<Parcel> parcels,
    required bool selecting,
    required String name,
    required String code,
  }) {
    if (selecting && provider.selectedIds.isNotEmpty) {
      if (_isDeliveryFlow) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _confirmReceivedPartial(
                context,
                s: s,
                provider: provider,
                parcels: parcels,
                name: name,
                code: code,
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                s.isRu
                    ? 'Подтвердить (${provider.selectedIds.length})'
                    : 'Тасдиқ (${provider.selectedIds.length})',
              ),
            ),
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () {
              provider.deleteSelected();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    s.isRu
                        ? 'Трек-коды удалены'
                        : 'Трек-кодҳо нест карда шуданд',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(
              s.isRu
                  ? 'Удалить выбранные (${provider.selectedIds.length})'
                  : 'Нест кардани интихобшуда (${provider.selectedIds.length})',
            ),
          ),
        ),
      );
    }

    if (status == ParcelStatusKey.received && !selecting) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(s.isRu
                      ? 'Удалить полученные?'
                      : 'Гирифташудаҳоро нест кунем?'),
                  content: Text(
                    s.isRu
                        ? 'Все трек-коды со статусом «Получен» будут удалены.'
                        : 'Ҳамаи трек-кодҳои «Гирифта шуд» нест мешаванд.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.isRu ? 'Оставить' : 'Гузоштан'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                          s.isRu ? 'Удалить все' : 'Ҳамаро нест кунед'),
                    ),
                  ],
                ),
              );
              if (ok == true) provider.deleteReceived();
            },
            icon: const Icon(Icons.delete_sweep_rounded),
            label: Text(s.isRu ? 'Очистить' : 'Тоза кардан'),
          ),
        ),
      );
    }

    if (_isDeliveryFlow && parcels.isNotEmpty && !selecting) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _confirmReceivedAll(
                    context,
                    s: s,
                    provider: provider,
                    parcels: parcels,
                    name: name,
                    code: code,
                  ),
                  child: Text(
                    s.isRu ? 'Получил все' : 'Ҳамаро гирифтам',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    provider.toggleSelectionMode(true);
                  },
                  child: Text(
                    s.isRu ? 'Получил частично' : 'Қисман гирифтам',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  static const _iconSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Image.asset(
              asset,
              width: _iconSize,
              height: _iconSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => Icon(
                Icons.account_balance_rounded,
                size: _iconSize,
                color: CargoColors.red.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
