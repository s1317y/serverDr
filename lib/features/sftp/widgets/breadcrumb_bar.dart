import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Path breadcrumb + up-directory button, matching the Stitch file
/// manager's sticky quick-path strip.
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({
    super.key,
    required this.segments,
    required this.onTapUp,
    required this.onTapSegment,
    required this.protocolLabel,
  });

  /// Path segments, root-first, e.g. ['var', 'www', 'html'].
  final List<String> segments;
  final VoidCallback onTapUp;
  final ValueChanged<int> onTapSegment;
  final String protocolLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                InkWell(
                  onTap: onTapUp,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.arrow_upward, size: 16, color: AppColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 6),
                _crumb('/', 0),
                for (var i = 0; i < segments.length; i++) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text('>', style: TextStyle(fontSize: 11, color: AppColors.outline)),
                  ),
                  _crumb(segments[i], i + 1, isLast: i == segments.length - 1),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                protocolLabel,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _crumb(String label, int index, {bool isLast = false}) {
    return InkWell(
      onTap: () => onTapSegment(index),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLast ? AppColors.surfaceContainerHighest : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
            color: isLast ? AppColors.onSurface : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
