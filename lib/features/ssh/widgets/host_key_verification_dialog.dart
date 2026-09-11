import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../models/host_key_verification.dart';

/// Real host-key verification UI, matching the Stitch "SSH Host
/// Verification" screen. Used for BOTH first-sighting and changed-key
/// cases — [request.isChanged] switches the tone/copy/available actions.
///
/// This is a modal, non-dismissible dialog (no tap-outside-to-cancel,
/// no back-button dismiss without an explicit choice) because a host-key
/// decision must never happen by accident. For a changed key there is
/// deliberately no casual "ignore and continue" — only Disconnect or an
/// explicit "I understand the risk" trust action, per the brief.
Future<HostKeyDecision> showHostKeyVerificationDialog(
  BuildContext context,
  HostKeyVerificationRequest request,
) async {
  final decision = await showDialog<HostKeyDecision>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Row(
          children: [
            Icon(
              request.isChanged ? Icons.gpp_bad : Icons.shield_outlined,
              color: request.isChanged ? AppColors.error : AppColors.tertiary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                request.isChanged ? 'SSH Host Key Changed' : 'New SSH Host Verification',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: request.isChanged ? AppColors.error : AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (request.isChanged) ...[
                const Text(
                  "The server's identity does not match the previously trusted fingerprint.",
                  style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.onSurface),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Possible reasons:',
                  style: TextStyle(fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  '•  Server was reinstalled\n'
                  '•  SSH keys were changed\n'
                  '•  Server was migrated\n'
                  '•  Possible man-in-the-middle attack',
                  style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 12),
              ] else ...[
                const Text(
                  "This server's identity has not been verified on this device.",
                  style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
              ],
              _infoRow('Target host', request.host),
              _infoRow('Port', '${request.port}'),
              _infoRow('Key type', request.keyType),
              const SizedBox(height: 8),
              const Text('Host key fingerprint', style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: request.isChanged ? AppColors.error : AppColors.outlineVariant,
                  ),
                ),
                child: SelectableText(
                  request.fingerprint,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    color: request.isChanged ? AppColors.error : AppColors.onSurface,
                  ),
                ),
              ),
              if (request.isChanged) ...[
                const SizedBox(height: 8),
                const Text('Previously trusted fingerprint', style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: SelectableText(
                    request.previousFingerprint!,
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                request.isChanged
                    ? 'Do not continue unless you are certain this change is expected.'
                    : 'Accepting will record this public key to this device only.',
                style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: request.isChanged
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context, HostKeyDecision.reject),
                  child: const Text('Disconnect'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.errorContainer, foregroundColor: AppColors.onErrorContainer),
                  onPressed: () => Navigator.pop(context, HostKeyDecision.trust),
                  child: const Text('I understand the risk'),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(context, HostKeyDecision.reject),
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, HostKeyDecision.trustOnce),
                  child: const Text('Connect Once'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.secondaryContainer, foregroundColor: AppColors.onSecondaryContainer),
                  onPressed: () => Navigator.pop(context, HostKeyDecision.trust),
                  child: const Text('Trust & Connect'),
                ),
              ],
      ),
    ),
  );
  return decision ?? HostKeyDecision.reject;
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurface)),
        ),
      ],
    ),
  );
}
