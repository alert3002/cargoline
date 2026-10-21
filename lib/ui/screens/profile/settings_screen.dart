import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/models/user_profile.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/ui/widgets/contact_picker.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final s = app.strings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: cargoProfileAppBar(
        context,
        Text(s.isRu ? 'Настройки' : 'Танзимот'),
      ),
      body: PullRefresh(
        onRefresh: () async {},
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.isRu ? 'Язык' : 'Забон',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                SegmentedButton<AppLocale>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return CargoColors.accent;
                      }
                      return CargoColors.accent.withValues(alpha: 0.08);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return CargoColors.accent;
                    }),
                    side: const WidgetStatePropertyAll(BorderSide.none),
                  ),
                  segments: const [
                    ButtonSegment(value: AppLocale.ru, label: Text('Рус')),
                    ButtonSegment(value: AppLocale.tj, label: Text('Тоҷ')),
                  ],
                  selected: {app.locale},
                  onSelectionChanged: (v) {
                    // Instant UI switch — no network
                    app.setLocale(v.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.isRu ? 'Пункт выдачи' : 'Нуқтаи додашуда',
                    style: theme.textTheme.titleLarge),
                ...PickupPoint.values.map(
                  (p) => RadioListTile<PickupPoint>(
                    value: p,
                    groupValue: app.pickupPoint,
                    activeColor: CargoColors.accent,
                    title: Text(p.label(s.isRu),
                        style: const TextStyle(fontSize: 13)),
                    onChanged: (v) {
                      if (v != null) app.setPickupPoint(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.isRu ? 'Тема' : 'Мавзӯъ',
                    style: theme.textTheme.titleLarge),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: app.themeMode,
                  activeColor: CargoColors.accent,
                  title: Text(s.isRu ? 'Светлая' : 'Равшан'),
                  onChanged: (v) => app.setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: app.themeMode,
                  activeColor: CargoColors.accent,
                  title: Text(s.isRu ? 'Тёмная' : 'Торик'),
                  onChanged: (v) => app.setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: app.themeMode,
                  activeColor: CargoColors.accent,
                  title: Text(s.isRu ? 'Системная' : 'Системавӣ'),
                  onChanged: (v) => app.setThemeMode(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.isRu ? 'Сменить аккаунт' : 'Ивази ҳисоб',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await app.logout();
                    if (context.mounted && Navigator.of(context).canPop()) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: CargoColors.red),
                  label: Text(
                    s.isRu ? 'Выйти' : 'Баромадан',
                    style: const TextStyle(color: CargoColors.red),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _deleteAccount(context),
                  icon: const Icon(Icons.delete_forever_rounded, color: CargoColors.red),
                  label: Text(
                    s.isRu ? 'Удалить аккаунт' : 'Нест кардани ҳисоб',
                    style: const TextStyle(color: CargoColors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.isRu ? 'Контакты' : 'Тамос',
                    style: theme.textTheme.titleLarge),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('WhatsApp'),
                  subtitle: Text(BrandConstants.deliveryPhoneDisplay),
                  onTap: () => launchUrl(
                    BrandConstants.whatsAppDelivery(),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Telegram'),
                  subtitle: Text(BrandConstants.adminPhoneDisplay),
                  onTap: () => launchUrl(
                    BrandConstants.telegramAdmin(),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                TextButton(
                  onPressed: () => showAdminContactPicker(context),
                  child: Text(s.isRu
                      ? 'Связаться с администратором'
                      : 'Бо админ тамос'),
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

Future<void> _deleteAccount(BuildContext context) async {
  final app = context.read<AppProvider>();
  final ru = app.strings.isRu;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ru ? 'Удалить аккаунт?' : 'Ҳисоб нест шавад?'),
      content: Text(
        ru
            ? 'Телефон, профиль, треки и сообщения будут удалены. Это нельзя отменить.'
            : 'Телефон, профил, трекҳо ва паёмҳо нест мешаванд. Бозгашт нест.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ru ? 'Отмена' : 'Бекор'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ru ? 'Удалить' : 'Нест кардан'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await context.read<AppProvider>().deleteAccount();
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  } on AuthException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
    );
  }
}
