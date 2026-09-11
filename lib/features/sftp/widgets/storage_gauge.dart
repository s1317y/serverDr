import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/byte_format.dart';

/// Thin storage-quota bar + "38.4 GB / 120 GB (32%)" label, from the
/// Stitch file manager's sticky header strip.
///
/// SFTP has no protocol-level way to report total filesystem capacity
/// (unlike the Phase 1 mock, which invented a plausible number) — when
/// [totalBytes] is 0, this shows the directory's total listed file size
/// with a "not reported by server" note instead of a fabricated quota bar.
class StorageGauge extends StatelessWidget {
  const StorageGauge({super.key, required this.usedBytes, required this.totalBytes});

  final int usedBytes;
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    if (totalBytes <= 0) {
      return Row(
        children: [
          const Icon(Icons.info_outline, size: 13, color: AppColors.outline),
          const SizedBox(width: 6),
          Text(
            '${formatBytes(usedBytes)} in this listing · capacity not reported over SFTP',
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
        ],
      );
    }

    final fraction = (usedBytes / totalBytes).clamp(0.0, 1.0);
    final percent = (fraction * 100).round();
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryContainer),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant),
            children: [
              TextSpan(
                text: formatBytes(usedBytes),
                style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500),
              ),
              const TextSpan(text: ' / '),
              TextSpan(text: '${formatBytes(totalBytes)} ($percent%)'),
            ],
          ),
        ),
      ],
    );
  }
}
