import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:cargo_line_tj/ui/screens/orders_list_screen.dart';
import 'package:cargo_line_tj/ui/screens/pending_tracks_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:cargo_line_tj/ui/widgets/animated_widgets.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:cargo_line_tj/ui/widgets/parcel_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cargo_line_tj/l10n/app_strings.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _trackController = TextEditingController();
  MarketplaceKey _marketplace = MarketplaceKey.pinduoduo;

  static const _mainStatuses = [
    ParcelStatusKey.chinaWarehouse,
    ParcelStatusKey.inTransit,
    ParcelStatusKey.tajikistanWarehouse,
    ParcelStatusKey.delivery,
  ];

  static const _statusIcons = {
    ParcelStatusKey.chinaWarehouse: Icons.warehouse_rounded,
    ParcelStatusKey.inTransit: Icons.local_shipping_rounded,
    ParcelStatusKey.tajikistanWarehouse: Icons.storefront_rounded,
    ParcelStatusKey.delivery: Icons.delivery_dining_rounded,
  };

  static const _statusAssets = {
    ParcelStatusKey.chinaWarehouse: CargoIconAssets.statusChina,
    ParcelStatusKey.inTransit: CargoIconAssets.statusTransit,
    ParcelStatusKey.tajikistanWarehouse: CargoIconAssets.statusTj,
    ParcelStatusKey.delivery: CargoIconAssets.statusDelivery,
  };

  @override
  void dispose() {
    _trackController.dispose();
    super.dispose();
  }

  Future<void> _pasteAndFocus() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _trackController.text = data.text!.trim();
      setState(() {});
    }
  }

  Future<void> _submit(AppStrings s) async {
    final err = await context.read<ParcelProvider>().addTrackCode(
          _trackController.text,
          _marketplace,
        );
    String? msg;
    switch (err) {
      case 'empty':
        msg = s.isRu ? 'Вставьте трек-код' : 'Трек-кодро гузоред';
      case 'short':
        msg = s.isRu
            ? 'Трек-код: от 8 до 32 символов'
            : 'Трек-код: аз 8 то 32 аломат';
      case 'invalid':
        msg = s.isRu
            ? 'Только латинские буквы, цифры и дефис'
            : 'Танҳо ҳарфҳои лотинӣ, рақам ва дефис';
      case 'duplicate':
        msg = s.isRu ? 'Уже добавлен' : 'Аллакай илова шудааст';
    }
    if (!mounted) return;
    if (err == null) {
      _trackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isRu ? 'Сохранено' : 'Захира шуд'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: CargoColors.success,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {});
    } else if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().strings;
    final theme = Theme.of(context);
    final provider = context.watch<ParcelProvider>();

    return SafeArea(
      bottom: false,
      child: Theme(
        data: theme.copyWith(
          cupertinoOverrideTheme: const CupertinoThemeData(
            primaryColor: CargoColors.red,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              await provider.syncFromServer();
              provider.refreshStatuses();
            },
            builder: (
              context,
              refreshState,
              pulledExtent,
              refreshTriggerPullDistance,
              refreshIndicatorExtent,
            ) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: CargoColors.red,
                      value: refreshState == RefreshIndicatorMode.drag
                          ? (pulledExtent / refreshTriggerPullDistance)
                              .clamp(0.0, 1.0)
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                s.ordersTitle,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeSlideIn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.isRu ? 'Добавить трек-код' : 'Трек-код илова кунед',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          MarketplaceKey.pinduoduo,
                          MarketplaceKey.taobao,
                          MarketplaceKey.alibaba1688,
                        ].map((m) {
                          final sel = _marketplace == m;
                          return ChoiceChip(
                            label: Text(s.marketplaceLabel(m)),
                            selected: sel,
                            onSelected: (_) =>
                                setState(() => _marketplace = m),
                            selectedColor:
                                CargoColors.red.withValues(alpha: 0.12),
                            visualDensity: VisualDensity.compact,
                            labelStyle: TextStyle(
                              color: sel
                                  ? CargoColors.red
                                  : CargoColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            side: BorderSide(
                              color:
                                  sel ? CargoColors.red : Colors.transparent,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _trackController,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 32,
                          style: const TextStyle(fontSize: 14),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9\-]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: s.trackCodeHint,
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            prefixIcon: const Icon(
                              Icons.content_paste_rounded,
                              color: CargoColors.red,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              tooltip: s.isRu ? 'Вставить' : 'Гузоштан',
                              onPressed: _pasteAndFocus,
                              icon: const Icon(Icons.paste_rounded, size: 20),
                            ),
                          ),
                          onSubmitted: (_) => _submit(s),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: () => _submit(s),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            s.isRu ? 'Отправить' : 'Фиристодан',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: PressableScale(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PendingTracksScreen(),
                    ),
                  );
                },
                child: SoftCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Image.asset(
                          CargoIconAssets.pendingTracks,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.pending_actions_rounded,
                            size: 28,
                            color: CargoColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ваши треккоды',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (provider.pendingParcels.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CargoColors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${provider.pendingParcels.length}',
                            style: const TextStyle(
                              color: CargoColors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: CargoColors.textSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverList.separated(
              itemCount: _mainStatuses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final status = _mainStatuses[index];
                final count = provider.countByStatus(status);
                return PressableScale(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrdersListScreen(status: status),
                      ),
                    );
                  },
                  child: SoftCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Image.asset(
                            _statusAssets[status]!,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, __, ___) => Icon(
                              _statusIcons[status]!,
                              size: 28,
                              color: CargoColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.statusLabel(status),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (count > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: CargoColors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: CargoColors.red,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const Icon(Icons.chevron_right_rounded,
                            color: CargoColors.textSecondary, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Lost item search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              child: SoftCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.lostItemSearch, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: s.trackCode,
                        prefixIcon:
                            const Icon(Icons.search, color: CargoColors.red),
                      ),
                      onSubmitted: (q) {
                        final found = provider.searchByTrackCode(q);
                        if (found != null) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              content: ParcelCard(parcel: found),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(s.done),
                                ),
                              ],
                            ),
                          );
                        }
                      },
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
