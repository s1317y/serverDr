import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/connections/models/connection_profile.dart';
import 'serverkit_logo.dart';
import 'status_dot.dart';

/// The header shared by every top-level screen in the Stitch prototypes:
/// brand lockup on the left, an active-connection pill in the center, and
/// transfers / connections-drawer / profile actions on the right.
///
/// IMPORTANT: this is a thin wrapper around Flutter's real [AppBar] —
/// specifically NOT a raw `Container` in a custom `PreferredSizeWidget`.
/// A real `AppBar` handles the status-bar top inset internally (it wraps
/// its content the same way `SafeArea` would, and Scaffold gives it extra
/// layout height for the inset automatically); a hand-rolled fixed-height
/// container does not, which was the source of the status-bar overlap
/// bug. Do not go back to a raw Container here even to tweak the layout —
/// reproduce the requirement via `AppBar`'s own parameters
/// (`toolbarHeight`, `titleSpacing`, `flexibleSpace`, ...).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.sectionLabel,
    required this.activeConnection,
    required this.onTapConnectionPill,
    required this.onTapConnections,
    this.onTapTransfers,
    this.pendingTransfers = 0,
  });

  final String sectionLabel;
  final ConnectionProfile? activeConnection;
  final VoidCallback onTapConnectionPill;
  final VoidCallback onTapConnections;
  final VoidCallback? onTapTransfers;
  final int pendingTransfers;

  static const double _toolbarHeight = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _toolbarHeight,
      backgroundColor: AppColors.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      shape: const Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      title: Row(
        children: [
          ServerKitBrandLockup(sectionLabel: sectionLabel),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: _ConnectionPill(
                connection: activeConnection,
                onTap: onTapConnectionPill,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _IconAction(
          icon: Icons.sync_alt,
          tooltip: 'Transfers',
          badgeCount: pendingTransfers,
          onTap: onTapTransfers,
        ),
        _IconAction(
          icon: Icons.dns_outlined,
          tooltip: 'Connections',
          onTap: onTapConnections,
        ),
        const SizedBox(width: 4),
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 18, color: AppColors.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.connection, required this.onTap});

  final ConnectionProfile? connection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = connection == null
        ? 'No server selected'
        : '${connection!.name} • ${connection!.host}';
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusDot(
                color: connection != null ? AppColors.secondary : AppColors.outline,
                glow: connection != null,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const Icon(Icons.expand_more, size: 16, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
              if (badgeCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
