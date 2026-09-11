import 'package:flutter/material.dart';

/// Exact `8x8` circular status indicator, per `DESIGN.md` → "Status Dots
/// & Badges". An optional soft glow reproduces the `shadow-[0_0_6px_...]`
/// used on the header's connection pill.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, this.glow = false, this.size = 8});

  final Color color;
  final bool glow;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 6)]
            : null,
      ),
    );
  }
}

/// Uppercase protocol/status badge — `20px` tall, `label-sm` text.
/// Matches `.px-1.5.py-0.5 rounded bg-surface-container-high ... uppercase`
/// used for things like `CONNECTED (0.04S LATENCY)` and `SSH` / `SFTP`
/// chips.
class ProtocolChip extends StatelessWidget {
  const ProtocolChip({
    super.key,
    required this.label,
    required this.foreground,
    this.background,
    this.dotColor,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color? background;
  final Color? dotColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background ?? const Color(0xFF222B33),
        border: Border.all(color: const Color(0xFF414752)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            StatusDot(color: dotColor!, size: 6),
            const SizedBox(width: 4),
          ],
          if (icon != null) ...[
            Icon(icon, size: 10, color: foreground),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
