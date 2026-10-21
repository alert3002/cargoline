import 'dart:math' as math;

import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/models/parcel.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:flutter/material.dart';

/// Compact Yiwu → Khujand truck progress for each track card.
///
/// Timeline:
/// - China warehouse: truck at start (day 0–3 hold).
/// - After ~3 days → in transit: truck advances ~1/12 per day (~12 days to border).
/// - Waiting at border until admin scan matches TJ warehouse.
/// - TJ / delivery / received: truck at destination.
class TrackTruckRoute extends StatelessWidget {
  const TrackTruckRoute({super.key, required this.parcel});

  final Parcel parcel;

  static const _traveledGreen = Color(0xFF22C55E);
  static const _remainingRed = Color(0xFFFF2A42);

  /// 0 = Yiwu, 1 = Khujand / border done.
  double get progress {
    switch (parcel.status) {
      case ParcelStatusKey.pendingMatch:
      case ParcelStatusKey.chinaWarehouse:
        return 0;
      case ParcelStatusKey.tajikistanWarehouse:
      case ParcelStatusKey.delivery:
      case ParcelStatusKey.received:
        return 1;
      case ParcelStatusKey.inTransit:
      case ParcelStatusKey.sorting:
        final start = parcel.createdAt.add(const Duration(days: 3));
        final days = DateTime.now().difference(start).inDays;
        return (days.clamp(0, 12) / 12.0).toDouble();
    }
  }

  bool get atBorderWaiting {
    if (parcel.status == ParcelStatusKey.tajikistanWarehouse ||
        parcel.status == ParcelStatusKey.delivery ||
        parcel.status == ParcelStatusKey.received) {
      return false;
    }
    if (parcel.status == ParcelStatusKey.inTransit ||
        parcel.status == ParcelStatusKey.sorting) {
      return progress >= 0.98;
    }
    return false;
  }

  String get dateLabel {
    final d = parcel.lastUpdate;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  String? get etaLabel {
    if (parcel.status == ParcelStatusKey.chinaWarehouse) {
      final leave = parcel.createdAt.add(const Duration(days: 3));
      final left = leave.difference(DateTime.now()).inDays;
      if (left > 0) return 'Выезд через ~$left дн.';
      return 'Готов к выезду';
    }
    if (parcel.status == ParcelStatusKey.inTransit ||
        parcel.status == ParcelStatusKey.sorting) {
      if (atBorderWaiting) return 'На границе — ждёт скан ТЖ';
      final daysLeft = ((1 - progress) * 12).ceil();
      return 'До границы ~$daysLeft дн.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eta = etaLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Добавлен: $dateLabel',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        if (eta != null) ...[
          const SizedBox(height: 2),
          Text(
            eta,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: atBorderWaiting
                  ? CargoColors.accent
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: LayoutBuilder(
            builder: (context, c) {
              return CustomPaint(
                size: Size(c.maxWidth, 52),
                painter: _CurvedRoadPainter(
                  progress: p,
                  isDark: isDark,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Text(
                        '义乌',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Text(
                        'Худжанд',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    _TruckOnPath(
                      width: c.maxWidth,
                      height: 52,
                      progress: p,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TruckOnPath extends StatelessWidget {
  const _TruckOnPath({
    required this.width,
    required this.height,
    required this.progress,
  });

  final double width;
  final double height;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final path = _CurvedRoadPainter.buildRoadPath(width, height);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return const SizedBox.shrink();

    final metric = metrics.first;
    final offset = metric.length * progress.clamp(0.0, 1.0);
    final tangent = metric.getTangentForOffset(offset);
    if (tangent == null) return const SizedBox.shrink();

    const truckSize = 22.0;
    final pos = tangent.position;
    final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);

    return Positioned(
      left: pos.dx - truckSize / 2,
      top: pos.dy - truckSize / 2,
      child: Transform.rotate(
        angle: angle,
        child: Image.asset(
          CargoIconAssets.statusTransit,
          width: truckSize,
          height: truckSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => Icon(
            Icons.local_shipping_rounded,
            size: truckSize,
            color: progress >= 0.98 ? CargoColors.accent : CargoColors.accentBlue,
          ),
        ),
      ),
    );
  }
}

class _CurvedRoadPainter extends CustomPainter {
  _CurvedRoadPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  static Path buildRoadPath(double width, double height) {
    final path = Path();
    final start = Offset(4, height - 8);
    final end = Offset(width - 4, 14);
    final control1 = Offset(width * 0.28, height - 4);
    final control2 = Offset(width * 0.72, 18);
    path.moveTo(start.dx, start.dy);
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildRoadPath(size.width, size.height);
    const roadWidth = 4.0;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = roadWidth
      ..strokeCap = StrokeCap.round
      ..color = TrackTruckRoute._remainingRed.withValues(alpha: isDark ? 0.55 : 0.35);

    canvas.drawPath(path, basePaint);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final traveledLen = metric.length * progress.clamp(0.0, 1.0);

    if (progress >= 1.0) {
      final allGreen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth
        ..strokeCap = StrokeCap.round
        ..color = TrackTruckRoute._traveledGreen;
      canvas.drawPath(path, allGreen);
      return;
    }

    if (traveledLen > 0.5) {
      final traveled = metric.extractPath(0, traveledLen);
      final greenPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth
        ..strokeCap = StrokeCap.round
        ..color = TrackTruckRoute._traveledGreen;
      canvas.drawPath(traveled, greenPaint);
    }

    if (traveledLen < metric.length - 0.5) {
      final remaining = metric.extractPath(traveledLen, metric.length);
      final redPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth
        ..strokeCap = StrokeCap.round
        ..color = TrackTruckRoute._remainingRed;
      canvas.drawPath(remaining, redPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedRoadPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
