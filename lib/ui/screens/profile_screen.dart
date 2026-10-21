import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:cargo_line_tj/core/pickup_hours.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:cargo_line_tj/ui/screens/ai_assistant_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/calculator_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/delivery_terms_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/forbidden_items_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/pickup_point_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/settings_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/statistics_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/support_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/tariffs_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/video_lessons_screen.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = app.strings;
    final user = app.user;
    final theme = Theme.of(context);
    final open = PickupHours.stateNow();

    final tiles = <_RowItem>[
      _RowItem(
        asset: CargoIconAssets.supportChat,
        title: s.isRu ? 'Техподдержка' : 'Дастгирии техникӣ',
        onTap: () => _push(context, const SupportScreen()),
      ),
      _RowItem(
        asset: CargoIconAssets.pickup,
        title: s.pickupPoint,
        subtitle: PickupHours.labelRu(open),
        subtitleColor: open == PickupOpenState.open
            ? CargoColors.success
            : CargoColors.accent,
        onTap: () => _push(context, const PickupPointScreen()),
      ),
      _RowItem(
        asset: CargoIconAssets.deliveryTerms,
        title: s.deliveryTerms,
        onTap: () => _push(context, const DeliveryTermsScreen()),
      ),
      _RowItem(
        asset: CargoIconAssets.profileTariffs,
        title: s.isRu ? 'Тарифы' : 'Тарифҳо',
        onTap: () => _push(context, const TariffsScreen()),
      ),
      _RowItem(
        asset: CargoIconAssets.calculator,
        title: s.deliveryCalculator,
        onTap: () => _push(context, const CalculatorScreen()),
      ),
      _RowItem(
        asset: CargoIconAssets.lessons,
        title: s.isRu ? 'ИИ Карго' : 'ИИ Карго',
        onTap: () => _push(context, const AiAssistantScreen()),
      ),
      _RowItem(
        asset: CargoIconAssets.lessons,
        title: s.freeCourse,
        onTap: () => _push(context, const VideoLessonsScreen()),
      ),
      _RowItem(
        asset: CargoIconAssets.forbiddenItems,
        title: s.isRu ? 'Запрещено' : 'Манъшуда',
        onTap: () => _push(context, const ForbiddenItemsScreen()),
      ),
      _RowItem(
        asset: CargoIconAssets.statistics,
        title: s.statistics,
        onTap: () => _push(context, const StatisticsScreen()),
      ),
    ];

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              await context.read<ParcelProvider>().syncFromServer();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: (user?.name ?? 'Клиент').split(' ').first,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF2A42),
                                ),
                              ),
                              if ((user?.name ?? '').contains(' '))
                                TextSpan(
                                  text:
                                      ' ${(user?.name ?? '').split(' ').skip(1).join(' ')}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0072FF),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.formattedPhone ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                        Text(
                          'ID: ${user?.clientCode ?? '—'}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: CargoColors.accent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _push(context, const SettingsScreen()),
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Color(0xFFFF2A42),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 3 groups × 3 rows with breathing space
          ...List.generate(3, (g) {
            final chunk = tiles.skip(g * 3).take(3).toList();
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(16, g == 0 ? 4 : 14, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final t = chunk[i];
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final fg = isDark ? Colors.white : Colors.black;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SoftCard(
                        onTap: t.onTap,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: Image.asset(
                                t.asset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.apps,
                                    color: CargoColors.accent),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: fg,
                                    ),
                                  ),
                                  if (t.subtitle != null)
                                    Text(
                                      t.subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: t.subtitleColor ?? fg,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                size: 20, color: fg.withValues(alpha: 0.55)),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: chunk.length,
                ),
              ),
            );
          }),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              child: SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isRu ? 'Соцсети' : 'Шабакаҳо',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Link(
                          asset: CargoIconAssets.whatsapp,
                          label: 'WhatsApp',
                          onTap: () => launchUrl(
                            BrandConstants.whatsAppDelivery(),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        _Link(
                          asset: CargoIconAssets.telegram,
                          label: 'Telegram',
                          onTap: () => launchUrl(
                            BrandConstants.telegramAdmin(),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        _Link(
                          asset: CargoIconAssets.instagram,
                          label: 'Instagram',
                          onTap: () => launchUrl(
                            Uri.parse('https://instagram.com/cargoline.tj'),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItem {
  const _RowItem({
    required this.asset,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
  });
  final String asset;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;
}

class _Link extends StatelessWidget {
  const _Link({
    required this.asset,
    required this.label,
    required this.onTap,
  });
  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.link, color: CargoColors.accent),
                ),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
