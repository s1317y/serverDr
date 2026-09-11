import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// The horizontally-scrolling row of shortcut keys above the command
/// input, matching `.terminal-key` buttons in the Stitch prototype.
///
/// Unlike the Phase 1 mock (which inserted characters into a text
/// buffer), every key here writes raw bytes straight to the real pty via
/// [onSendRaw] — this is how a real terminal's control keys work; there
/// is no "buffer" for Ctrl+C to sit in.
class TerminalKeyBar extends StatelessWidget {
  const TerminalKeyBar({super.key, required this.onSendRaw, required this.onOpenPalette});

  final ValueChanged<List<int>> onSendRaw;
  final VoidCallback onOpenPalette;

  // Standard ANSI/VT100 byte sequences.
  static const _ctrlC = [0x03];
  static const _ctrlD = [0x04];
  static const _ctrlL = [0x0C];
  static const _ctrlZ = [0x1A];
  static const _tab = [0x09];
  static const _esc = [0x1B];
  static const _up = [0x1B, 0x5B, 0x41]; // ESC [ A
  static const _down = [0x1B, 0x5B, 0x42]; // ESC [ B
  static const _right = [0x1B, 0x5B, 0x43]; // ESC [ C
  static const _left = [0x1B, 0x5B, 0x44]; // ESC [ D

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Key(label: 'CTRL+C', color: AppColors.error, bold: true, onTap: () => onSendRaw(_ctrlC)),
            _Key(label: 'CTRL+D', onTap: () => onSendRaw(_ctrlD)),
            _Key(label: 'CTRL+L', onTap: () => onSendRaw(_ctrlL)),
            _Key(label: 'CTRL+Z', onTap: () => onSendRaw(_ctrlZ)),
            _Key(label: 'TAB', onTap: () => onSendRaw(_tab)),
            _Key(label: 'ESC', onTap: () => onSendRaw(_esc)),
            _IconKey(icon: Icons.arrow_upward, onTap: () => onSendRaw(_up)),
            _IconKey(icon: Icons.arrow_downward, onTap: () => onSendRaw(_down)),
            _IconKey(icon: Icons.arrow_back, onTap: () => onSendRaw(_left)),
            _IconKey(icon: Icons.arrow_forward, onTap: () => onSendRaw(_right)),
            _Key(label: '/', onTap: () => onSendRaw('/'.codeUnits)),
            _Key(label: '|', onTap: () => onSendRaw('|'.codeUnits)),
            _Key(label: '~', onTap: () => onSendRaw('~'.codeUnits)),
            const SizedBox(width: 4),
            Material(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                onTap: onOpenPalette,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 16, color: AppColors.onPrimaryContainer),
                      SizedBox(width: 4),
                      Text(
                        'PALETTE',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.color, this.bold = false});

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 32,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: color ?? AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 16, color: AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}
