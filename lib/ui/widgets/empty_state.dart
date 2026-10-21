import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.iconAsset,
    this.iconGradient,
    this.illustration,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || illustration != null);

  final IconData? icon;
  final String? iconAsset;
  final List<Color>? iconGradient;
  final String? illustration;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              CargoIcon(
                asset: iconAsset ?? CargoIconAssets.navOrders,
                icon: icon!,
                size: 88,
                gradient: iconGradient ?? Cargo3DIcon.orders,
              ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
