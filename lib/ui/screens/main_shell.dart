import 'dart:async';

import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:cargo_line_tj/ui/screens/home_screen.dart';
import 'package:cargo_line_tj/ui/screens/market_screen.dart';
import 'package:cargo_line_tj/ui/screens/orders_screen.dart';
import 'package:cargo_line_tj/ui/screens/profile_screen.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _barIndex = 0;
  Timer? _poll;
  bool _syncing = false;
  final _visited = <int>{0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAll();
      // Lighter poll — avoids UI jank from constant network.
      _poll = Timer.periodic(const Duration(seconds: 18), (_) {
        if (mounted) _syncAll();
      });
    });
  }

  Future<void> _syncAll() async {
    if (_syncing || !mounted) return;
    _syncing = true;
    try {
      final parcels = context.read<ParcelProvider>();
      final app = context.read<AppProvider>();
      await Future.wait([
        parcels.syncFromServer(),
        app.refreshUnreadFromServer(),
      ]);
      if (mounted) parcels.refreshStatuses();
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _syncAll();
    }
  }

  void _onTab(int i) {
    if (i == _barIndex) return;
    setState(() {
      _barIndex = i;
      _visited.add(i);
    });
    // Sync only when opening Orders (status) or Home (badge).
    if (i == 0 || i == 1) {
      _syncAll();
    }
  }

  Widget _page(int i) {
    // Lazy build — don't keep all 4 heavy trees hot at once until visited.
    if (!_visited.contains(i) && i != _barIndex) {
      return const SizedBox.shrink();
    }
    switch (i) {
      case 0:
        return const HomeScreen();
      case 1:
        return const OrdersScreen();
      case 2:
        return const MarketScreen();
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: _barIndex,
        sizing: StackFit.expand,
        children: [
          _page(0),
          _page(1),
          _page(2),
          _page(3),
        ],
      ),
      bottomNavigationBar: CargoBottomBar(
        selectedIndex: _barIndex,
        onTap: _onTab,
      ),
    );
  }
}
