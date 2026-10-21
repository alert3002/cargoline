import 'dart:convert';

import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:cargo_line_tj/services/content_api.dart';
import 'package:http/http.dart' as http;
import 'package:cargo_line_tj/core/pickup_hours.dart';
import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:cargo_line_tj/ui/screens/notifications_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/delivery_terms_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/pickup_point_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile/tariffs_screen.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _remoteIdBannerUrl;
  List<ChinaAddress> _addresses = const [];
  int _addrPage = 0;
  final _addrController = PageController();
  final _contentApi = ContentApi();

  @override
  void dispose() {
    _addrController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRemoteIdBanner();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final rows = await _contentApi.warehouses();
      if (!mounted) return;
      setState(() {
        _addresses = rows;
        if (_addrPage >= rows.length) _addrPage = 0;
      });
    } catch (_) {}
  }

  Future<void> _loadRemoteIdBanner() async {
    try {
      final base = AuthService.defaultBaseUrl;
      final res = await http
          .get(Uri.parse('$base/api/v1/settings/id-banner'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final path = data['url'] as String?;
      if (!mounted) return;
      if (path == null || path.isEmpty) {
        setState(() => _remoteIdBannerUrl = null);
        return;
      }
      final full = path.startsWith('http') ? path : '$base$path';
      setState(() => _remoteIdBannerUrl = full);
    } catch (_) {}
  }

  Future<void> _copy(BuildContext context, String text, AppStrings s) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.copied),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openMarket(String key) async {
    // 1) Custom schemes — try launch directly (canLaunchUrl is unreliable on Android 11+)
    final schemes = BrandConstants.marketplaceAppSchemes[key] ?? const <String>[];
    for (final s in schemes) {
      try {
        final ok = await launchUrl(
          Uri.parse(s),
          mode: LaunchMode.externalApplication,
        );
        if (ok) return;
      } catch (_) {}
    }

    // 2) Android package intent (opens installed APK even if not from Play Store)
    final pkg = BrandConstants.marketplacePackages[key];
    if (pkg != null && Theme.of(context).platform == TargetPlatform.android) {
      try {
        final intent = Uri.parse(
          'intent://#Intent;scheme=https;package=$pkg;end',
        );
        final ok = await launchUrl(intent, mode: LaunchMode.externalApplication);
        if (ok) return;
      } catch (_) {}
    }

    // 3) HTTPS → prefers installed app via App Links / non-browser
    final web = BrandConstants.marketplaceUrls[key];
    if (web != null) {
      try {
        final ok = await launchUrl(
          Uri.parse(web),
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (ok) return;
      } catch (_) {}
    }

    // 4) Not installed → store
    final store = Theme.of(context).platform == TargetPlatform.iOS
        ? (BrandConstants.marketplaceIosStoreUrls[key] ??
            BrandConstants.marketplaceStoreUrls[key])
        : BrandConstants.marketplaceStoreUrls[key];
    if (store != null) {
      await launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _refresh() async {
    final parcels = context.read<ParcelProvider>();
    final app = context.read<AppProvider>();
    await parcels.syncFromServer();
    parcels.refreshStatuses();
    await app.refreshUnreadFromServer();
    await _loadRemoteIdBanner();
    await _loadAddresses();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = app.strings;
    final user = app.user;
    final code = user?.clientCode ?? 'TJ----';
    final warehouseSuffix = user?.warehouseSuffix ?? code;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unread = user?.unreadNotifications ?? 0;
    final openState = PickupHours.stateNow();

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
            onRefresh: _refresh,
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
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 0),
              child: Row(
                children: [
                  const CargoLogo(height: 42, heroTag: null, showText: true),
                  const Spacer(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: 'Уведомления',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.notifications_none_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 28,
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: CargoColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _IdBanner(
              isDark: isDark,
              clientCode: code,
              phone: user?.formattedPhone ?? '',
              name: user?.name ?? '',
              remoteBannerUrl: _remoteIdBannerUrl,
              onCopy: () => _copy(context, code, s),
            ),
          ),
          // warehouseSuffix used below for address card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _QuickAction(
                    asset: CargoIconAssets.homePickup,
                    title: 'Пункт выдачи',
                    subtitle: PickupHours.labelRu(openState),
                    titleColor: const Color(0xFF7B1FA2),
                    subtitleColor: openState == PickupOpenState.open
                        ? CargoColors.success
                        : openState == PickupOpenState.breakTime
                            ? Colors.orange
                            : CargoColors.accent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PickupPointScreen(),
                      ),
                    ),
                  ),
                  _QuickAction(
                    asset: CargoIconAssets.homeTariffs,
                    title: 'Тарифы',
                    subtitle: 'от 0.67\$/кг',
                    titleColor: const Color(0xFFF9A825),
                    subtitleColor: const Color(0xFFFF2A42),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TariffsScreen()),
                    ),
                  ),
                  _QuickAction(
                    asset: CargoIconAssets.homeDeliveryTerms,
                    title: 'Доставка',
                    subtitle: 'от 12 до 20 дн.',
                    titleColor: const Color(0xFF43A047),
                    subtitleColor: const Color(0xFFFF2A42),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeliveryTermsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Маркетплейсы Китая',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '中国市场',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.55),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: CargoColors.red.withValues(alpha: 0.85),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _Market(
                      label: 'Pinduoduo',
                      asset: CargoIconAssets.marketPinduoduo,
                      onTap: () => _openMarket('pinduoduo'),
                    ),
                    _Market(
                      label: '1688',
                      asset: CargoIconAssets.market1688,
                      onTap: () => _openMarket('1688'),
                    ),
                    _Market(
                      label: 'Taobao',
                      asset: CargoIconAssets.marketTaobao,
                      onTap: () => _openMarket('taobao'),
                    ),
                    _Market(
                      label: 'Poizon',
                      asset: CargoIconAssets.marketPoizon,
                      onTap: () => _openMarket('poizon'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              child: _AddressSlider(
                controller: _addrController,
                addresses: _addresses.isEmpty
                    ? [
                        ChinaAddress(
                          id: 0,
                          name: s.isRu
                              ? 'Адрес склада в Китае'
                              : 'Суроғаи анбор дар Чин',
                          recipient: 'MA',
                          phone: BrandConstants.warehousePhoneCn,
                          region: BrandConstants.warehouseRegionCn,
                          detail: BrandConstants.warehouseStreetCn,
                        ),
                      ]
                    : _addresses,
                page: _addrPage,
                suffix: warehouseSuffix,
                onPage: (i) => setState(() => _addrPage = i),
                onCopy: (text) => _copy(context, text, s),
                copyAllLabel: s.copyAll,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _IdBanner extends StatelessWidget {
  const _IdBanner({
    required this.isDark,
    required this.clientCode,
    required this.phone,
    required this.name,
    required this.onCopy,
    this.remoteBannerUrl,
  });

  final bool isDark;
  final String clientCode;
  final String phone;
  final String name;
  final VoidCallback onCopy;
  final String? remoteBannerUrl;

  Widget _bannerBackground(bool isDark) {
    final asset = Image.asset(
      CargoIconAssets.profileIdBanner,
      fit: BoxFit.cover,
      alignment: const Alignment(0.55, 0.0),
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Container(
        color: isDark ? const Color(0xFF050507) : const Color(0xFF0D1B2A),
      ),
    );
    final url = remoteBannerUrl;
    if (url == null || url.isEmpty) return asset;
    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: const Alignment(0.55, 0.0),
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => asset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 136,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CargoColors.red.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
            blurRadius: 4,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _bannerBackground(isDark),
            // Dim right side (logo watermark) without zoom
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xDDB71C1C),
                    const Color(0x66C62828),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.32, 0.62, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    name.isEmpty ? 'Клиент' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        clientCode,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: const Color(0xFFFF2A42)
                                  .withValues(alpha: 0.85),
                            ),
                            const Shadow(blurRadius: 6, color: Colors.black54),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: onCopy,
                        child: const Icon(
                          Icons.copy_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.subtitleColor,
  });

  final String asset;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Color? subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.12
                    : 0.55,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CargoColors.red.withValues(alpha: 0.85),
                width: 1,
              ),
              boxShadow: _oneSidedBlackShadow(context),
            ),
            child: Column(
              children: [
                Image.asset(
                  asset,
                  height: 52,
                  width: 52,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.place, size: 40, color: Color(0xFFFF2A42)),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: titleColor ?? Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor ?? Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Market extends StatelessWidget {
  const _Market({
    required this.label,
    required this.asset,
    required this.onTap,
  });

  final String label;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [
              CargoIcon(
                asset: asset,
                icon: Icons.storefront_rounded,
                size: 58,
                padded: false,
                showShadow: false,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<BoxShadow> _oneSidedBlackShadow(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.16),
      blurRadius: 3,
      offset: const Offset(4, 4),
    ),
  ];
}

class _AddressSlider extends StatelessWidget {
  const _AddressSlider({
    required this.controller,
    required this.addresses,
    required this.page,
    required this.suffix,
    required this.onPage,
    required this.onCopy,
    required this.copyAllLabel,
  });

  final PageController controller;
  final List<ChinaAddress> addresses;
  final int page;
  final String suffix;
  final ValueChanged<int> onPage;
  final ValueChanged<String> onCopy;
  final String copyAllLabel;

  String _detail(ChinaAddress a) {
    final base = a.detail.trim();
    if (suffix.isEmpty || base.contains(suffix)) return base;
    return '$base $suffix'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: controller,
            itemCount: addresses.length,
            onPageChanged: onPage,
            itemBuilder: (context, i) {
              final a = addresses[i];
              final detail = _detail(a);
              final block = [
                if (a.recipient.isNotEmpty) '收货人：${a.recipient}',
                if (a.phone.isNotEmpty) '手机号码：${a.phone}',
                if (a.region.isNotEmpty) '所在地区：${a.region}',
                if (detail.isNotEmpty) '详细地址：$detail',
                if (a.notes.isNotEmpty) a.notes,
              ].join('\n');
              return _ChinaAddressCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name.isEmpty ? 'Адрес склада' : a.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (a.recipient.isNotEmpty)
                      _AddrLine('收货人', a.recipient, () => onCopy(a.recipient)),
                    if (a.phone.isNotEmpty)
                      _AddrLine('手机号码', a.phone, () => onCopy(a.phone)),
                    if (a.region.isNotEmpty)
                      _AddrLine('所在地区', a.region, () => onCopy(a.region)),
                    if (detail.isNotEmpty)
                      _AddrLine('详细地址', detail, () => onCopy(detail)),
                    if (a.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(a.notes, style: theme.textTheme.bodySmall),
                      ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => onCopy(block),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: Text(
                          copyAllLabel,
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CargoColors.red,
                          side: BorderSide(
                            color: CargoColors.red.withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (addresses.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < addresses.length; i++)
                Container(
                  width: i == page ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == page
                        ? CargoColors.red
                        : CargoColors.red.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Marketplace-style red frame (no blue LED blur).
class _ChinaAddressCard extends StatelessWidget {
  const _ChinaAddressCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CargoColors.red.withValues(alpha: 0.85),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _AddrLine extends StatelessWidget {
  const _AddrLine(this.cn, this.value, this.onCopy);
  final String cn;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: CargoColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              cn,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: CargoColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 11, height: 1.2),
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 14, color: CargoColors.accent),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
