import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The ServerKit brand mark.
///
/// Reproduced from `serverkit_logo/code.html` (a static 48x48 SVG) as a
/// [CustomPainter] instead of pulling in `flutter_svg` for a single static
/// asset — keeps Phase 1 dependency-free per the "avoid unnecessary
/// packages" instruction. Coordinates below are copied directly from the
/// original `viewBox="0 0 48 48"` SVG.
class ServerKitLogo extends StatelessWidget {
  const ServerKitLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48;
    canvas.save();
    canvas.scale(scale);

    // Outer rounded frame.
    final framePaint = Paint()
      ..color = const Color(0xFF161B22)
      ..style = PaintingStyle.fill;
    final frameBorder = Paint()
      ..color = const Color(0xFF30363D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final frameRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0.75, 0.75, 46.5, 46.5),
      const Radius.circular(10),
    );
    canvas.drawRRect(frameRect, framePaint);
    canvas.drawRRect(frameRect, frameBorder);

    // Top rack unit (blue-bordered, "active" row).
    _drawRackUnit(
      canvas,
      top: 10,
      borderColor: const Color(0xFF388BFD),
      dotColor: const Color(0xFF58A6FF),
    );

    // Bottom rack unit (idle row).
    _drawRackUnit(
      canvas,
      top: 27,
      borderColor: const Color(0xFF30363D),
      dotColor: const Color(0xFF30363D),
    );

    // Dashed connectors between the two units.
    final dashPaint = Paint()
      ..color = const Color(0xFF58A6FF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    _drawDashedLine(canvas, const Offset(20, 21), const Offset(20, 27), dashPaint);
    _drawDashedLine(canvas, const Offset(28, 21), const Offset(28, 27), dashPaint);

    canvas.restore();
  }

  void _drawRackUnit(
    Canvas canvas, {
    required double top,
    required Color borderColor,
    required Color dotColor,
  }) {
    final fill = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, top, 32, 11),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);

    final centerY = top + 5.5;
    canvas.drawCircle(
      Offset(13, centerY),
      1.5,
      Paint()..color = const Color(0xFF3FB950),
    );
    canvas.drawCircle(Offset(18, centerY), 1.5, Paint()..color = dotColor);

    final linePaint = Paint()
      ..color = const Color(0xFF30363D)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(26, centerY), Offset(35, centerY), linePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 2.0;
    const gapLength = 2.0;
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    var distance = 0.0;
    while (distance < totalLength) {
      final segmentEnd = (distance + dashLength).clamp(0, totalLength);
      canvas.drawLine(
        start + direction * distance,
        start + direction * segmentEnd.toDouble(),
        paint,
      );
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => false;
}

/// Compact lockup used in the top app bar: logo + "ServerKit" + section
/// label (e.g. "Terminal", "Files"), matching the header markup shared by
/// every Stitch screen.
class ServerKitBrandLockup extends StatelessWidget {
  const ServerKitBrandLockup({super.key, required this.sectionLabel});

  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ServerKitLogo(size: 32),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ServerKit',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.16,
                color: AppColors.onSurface,
                height: 1,
              ),
            ),
            Text(
              sectionLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
