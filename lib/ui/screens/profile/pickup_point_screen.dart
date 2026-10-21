import 'package:cargo_line_tj/core/pickup_hours.dart';
import 'package:cargo_line_tj/models/user_profile.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:url_launcher/url_launcher.dart';

class PickupPointScreen extends StatelessWidget {
  const PickupPointScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = app.strings;
    final theme = Theme.of(context);
    final state = PickupHours.stateNow();
    final statusColor = switch (state) {
      PickupOpenState.open => CargoColors.success,
      PickupOpenState.breakTime => Colors.orange,
      PickupOpenState.closed => CargoColors.accent,
    };

    return Scaffold(
      appBar: cargoProfileAppBar(context, Text(s.pickupPoint)),
      body: PullRefresh(
        onRefresh: () async {},
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PickupPoint.didor.label(s.isRu),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  PickupHours.labelRu(state),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(PickupHours.scheduleTextRu, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(PickupPoint.mapUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(s.isRu ? 'Посмотреть на карте' : 'Дар харита'),
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
