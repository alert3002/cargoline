import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// iOS-like translucent bottom bar with droplet pill animation.
class CargoBottomBar extends StatelessWidget {
  const CargoBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    Icons.home_outlined,
    Icons.local_shipping_outlined,
    Icons.storefront_outlined,
    Icons.person_outline_rounded,
  ];
  static const _iconsSel = [
    Icons.home_rounded,
    Icons.local_shipping_rounded,
    Icons.storefront_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().strings;
    final labels = [s.navHome, s.navOrders, 'Маркет', s.navProfile];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark
        ? Colors.black.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.82);

    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: barBg,
          border: Border(
            top: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth / 4;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      left: selectedIndex * w + w * 0.18,
                      top: 8,
                      child: Container(
                        width: w * 0.64,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: CargoColors.accent.withValues(alpha: 0.14),
                          border: Border.all(
                            color: CargoColors.accent.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (i != selectedIndex) onTap(i);
                              },
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: i == selectedIndex ? 1.08 : 1,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      i == selectedIndex
                                          ? _iconsSel[i]
                                          : _icons[i],
                                      size: 24,
                                      color: _color(isDark, i == selectedIndex),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    labels[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: i == selectedIndex
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _color(isDark, i == selectedIndex),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _color(bool isDark, bool selected) {
    if (!isDark) {
      return selected ? CargoColors.lightText : const Color(0xFF8E8E8E);
    }
    if (selected) {
      return Color.lerp(const Color(0xFFF2F2F2), CargoColors.accent, 0.28)!;
    }
    return const Color(0xFFD0D0D0);
  }
}
