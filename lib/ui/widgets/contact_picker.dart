import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showAdminContactPicker(BuildContext context) async {
  final isRu = context.read<AppProvider>().strings.isRu;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? const Color(0xFF333333)
              : const Color(0xFF111111).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.phone_rounded, color: Color(0xFF0072FF)),
            title: Text(isRu ? 'Позвонить' : 'Занг задан'),
            subtitle: Text(BrandConstants.adminPhoneDisplay),
            onTap: () => _open(ctx, BrandConstants.telAdmin()),
          ),
          ListTile(
            leading: const CargoIcon(
              asset: CargoIconAssets.whatsapp,
              icon: Icons.chat_rounded,
              size: 36,
            ),
            title: const Text('WhatsApp'),
            subtitle: Text(BrandConstants.adminPhoneDisplay),
            onTap: () => _open(ctx, BrandConstants.whatsAppAdmin()),
          ),
          ListTile(
            leading: const CargoIcon(
              asset: CargoIconAssets.telegram,
              icon: Icons.send_rounded,
              size: 36,
            ),
            title: const Text('Telegram'),
            onTap: () => _open(ctx, BrandConstants.telegramAdmin()),
          ),
        ],
      ),
    ),
  );
}

Future<void> _open(BuildContext context, Uri uri) async {
  Navigator.pop(context);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
