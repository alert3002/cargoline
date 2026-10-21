import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:flutter/material.dart';

/// Pull down from the top to reload the page.
class PullRefresh extends StatelessWidget {
  const PullRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: CargoColors.red,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
