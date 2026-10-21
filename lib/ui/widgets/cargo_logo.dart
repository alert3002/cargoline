import 'package:flutter/material.dart';

/// Logo + «Cargo Line TJ». Static by default (no blink).
class CargoLogo extends StatelessWidget {
  const CargoLogo({
    super.key,
    this.height = 48,
    this.heroTag = 'cargo_logo',
    this.showText = true,
  });

  final double height;
  final String? heroTag;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_cargoline.png',
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Icon(
            Icons.local_shipping_rounded,
            size: height * 0.85,
            color: const Color(0xFFD32F2F),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Cargo Line',
                  style: TextStyle(
                    fontSize: height * 0.36,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF9EC5FF)
                        : const Color(0xFF0D253F),
                  ),
                ),
                TextSpan(
                  text: ' TJ',
                  style: TextStyle(
                    fontSize: height * 0.36,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF2A42),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    if (heroTag == null) return row;
    return Hero(tag: heroTag!, child: row);
  }
}
