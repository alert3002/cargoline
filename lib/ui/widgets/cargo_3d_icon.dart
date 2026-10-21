import 'package:flutter/material.dart';

class Cargo3DIcon extends StatelessWidget {
  const Cargo3DIcon(
    this.icon, {
    super.key,
    this.size = 48,
    this.gradient,
    this.iconColor = Colors.white,
    this.iconSize,
    this.borderRadius = 14,
  });

  final IconData icon;
  final double size;
  final List<Color>? gradient;
  final Color iconColor;
  final double? iconSize;
  final double borderRadius;

  static const home = [Color(0xFF4DA3FF), Color(0xFF0072FF)];
  static const orders = [Color(0xFFFF5A6E), Color(0xFFE01030)];
  static const ai = [Color(0xFFB388FF), Color(0xFF7C4DFF)];
  static const messages = [Color(0xFF5CE1C5), Color(0xFF00B894)];
  static const profile = [Color(0xFFFFB347), Color(0xFFFF8C00)];
  static const china = [Color(0xFFFF6B6B), Color(0xFFEE2A42)];
  static const transit = [Color(0xFF64B5F6), Color(0xFF1976D2)];
  static const warehouse = [Color(0xFF81C784), Color(0xFF388E3C)];
  static const delivery = [Color(0xFFFFD54F), Color(0xFFFFA000)];
  static const support = [Color(0xFF4FC3F7), Color(0xFF0288D1)];
  static const payment = [Color(0xFFBA68C8), Color(0xFF7B1FA2)];
  static const lessons = [Color(0xFFCE93D8), Color(0xFF8E24AA)];
  static const stats = [Color(0xFF4DB6AC), Color(0xFF00897B)];
  static const calc = [Color(0xFFFFAB91), Color(0xFFE64A19)];
  static const pickup = [Color(0xFFFF8A65), Color(0xFFE65100)];
  static const admin = [Color(0xFF7986CB), Color(0xFF3949AB)];

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? home;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(colors: [colors.first, colors.last]),
      ),
      child: Icon(icon, size: iconSize ?? size * 0.48, color: iconColor),
    );
  }
}

abstract final class CargoIconAssets {
  static const _base = 'assets/images/icons_3d';

  static const logo = 'assets/images/logo_cargoline.png';
  static const splash = 'assets/images/splash_photo.png';

  static const statusChina = '$_base/status_china.png';
  static const statusTransit = '$_base/status_transit.png';
  static const statusTj = '$_base/status_tj.png';
  static const statusDelivery = '$_base/status_delivery.png';
  static const statusReceived = '$_base/status_received.png';
  static const pendingTracks = 'assets/images/icon_pending_tracks.png';

  static const marketPinduoduo = '$_base/market_pinduoduo.png';
  static const market1688 = '$_base/market_1688.png';
  static const marketTaobao = '$_base/market_taobao.png';
  static const marketPoizon = '$_base/market_poizon.png';

  static const bankAlif = '$_base/bank_alif.png';
  static const bankDushanbe = '$_base/bank_dushanbe.png';
  static const bankEskhata = '$_base/bank_eskhata.png';

  static const pickup = '$_base/pickup.png';
  static const deliveryTerms = '$_base/delivery_terms.png';
  static const lessons = '$_base/lessons.png';
  static const statistics = '$_base/statistics.png';
  static const calculator = '$_base/calculator.png';

  static const whatsapp = '$_base/whatsapp.png';
  static const telegram = '$_base/telegram.png';
  static const instagram = '$_base/instagram.png';
  static const supportChat = '$_base/support_chat.png';

  static const homePickup = '$_base/home_pickup.png';
  static const homeTariffs = '$_base/home_tariffs.png';
  static const homeDeliveryTerms = '$_base/home_delivery_terms.png';
  static const profileTariffs = '$_base/profile_tariffs.png';
  static const forbiddenItems = '$_base/forbidden_items.png';
  static const profileIdBanner = '$_base/profile_id_banner.png';

  static const navHome = logo;
  static const navOrders = statusChina;
  static const navAi = calculator;
  static const navMessages = telegram;
  static const navProfile = pickup;
  static const admin = '$_base/admin.png';
  static const support = supportChat;
  static const payment = bankAlif;
  static const marketplace = marketPinduoduo;
}

/// iOS-like glass icon well: soft fill + dark outer shadow, no colored frame.
class CargoIcon extends StatelessWidget {
  const CargoIcon({
    super.key,
    required this.asset,
    required this.icon,
    this.size = 40,
    this.gradient,
    this.glow = false,
    this.padded = true,
    this.showShadow = true,
  });

  final String asset;
  final IconData icon;
  final double size;
  final List<Color>? gradient;
  final bool glow;
  final bool padded;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadows = showShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
        : <BoxShadow>[];

    final img = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      cacheWidth: (size * 3).round().clamp(64, 512),
      errorBuilder: (_, __, ___) => Cargo3DIcon(
        icon,
        size: size,
        gradient: gradient ?? Cargo3DIcon.orders,
      ),
    );

    if (!padded) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(boxShadow: shadows),
        child: img,
      );
    }

    return Container(
      width: size + 12,
      height: size + 12,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.7),
          width: 0.6,
        ),
        boxShadow: shadows,
      ),
      child: img,
    );
  }
}
