import 'package:flutter/material.dart';

/// Red → blue gradient text (CargoLine brand).
class GradientBrandText extends StatelessWidget {
  const GradientBrandText(
    this.text, {
    super.key,
    this.fontSize = 26,
    this.fontWeight = FontWeight.w800,
    this.italic = true,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final bool italic;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFFF2A42), Color(0xFF0072FF), Color(0xFF00D2FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => _gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

/// Gradient card (admin contact, CTAs).
class GradientBrandCard extends StatelessWidget {
  const GradientBrandCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0072FF), Color(0xFFFF2A42)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2A42).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: box,
      ),
    );
  }
}
