import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cargo = CargoTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cargo.card,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: cargo.muted),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: 'RU',
            selected: app.locale == AppLocale.ru,
            onTap: () => app.setLocale(AppLocale.ru),
          ),
          _LangChip(
            label: 'TJ',
            selected: app.locale == AppLocale.tj,
            onTap: () => app.setLocale(AppLocale.tj),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cargo = CargoTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CargoColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : cargo.textSecondary,
          ),
        ),
      ),
    );
  }
}
