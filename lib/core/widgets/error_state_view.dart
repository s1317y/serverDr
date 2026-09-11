import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../errors/app_failure.dart';

/// A single, consistent way to render every error state called for in the
/// brief (connection refused, auth failed, host unreachable, permission
/// denied, file not found, transfer failed, host key changed, unsupported
/// operation, disconnected) — each with at least one recovery action.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.failure,
    required this.actions,
  });

  final AppFailure failure;
  final List<RecoveryAction> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppFailure.iconFor(failure.kind),
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              failure.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            if (failure.detail != null) ...[
              const SizedBox(height: 6),
              Text(
                failure.detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: actions
                    .map(
                      (a) => a.isPrimary
                          ? ElevatedButton(onPressed: a.onPressed, child: Text(a.label))
                          : OutlinedButton(onPressed: a.onPressed, child: Text(a.label)),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple centered empty-state view (e.g. "This folder is empty").
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.outline),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Standard loading state — used while mock services simulate latency.
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(
              label!,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
