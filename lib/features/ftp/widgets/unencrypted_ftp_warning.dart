import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// The mandatory "Unencrypted FTP" warning. Every code path that connects
/// over plain FTP (never FTPS/SFTP) must show this before proceeding, and
/// it must never be silently skipped or remembered as "don't ask again" —
/// per the brief: "Never hide this warning."
Future<bool> showUnencryptedFtpWarning(BuildContext context, {required String host}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_open, color: AppColors.error, size: 20),
          SizedBox(width: 8),
          Text('Unencrypted FTP'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are about to connect to $host using traditional FTP.',
            style: const TextStyle(fontFamily: 'Geist', fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text(
            'FTP is not encrypted. Your username, password, and all transferred '
            'file contents may be visible to anyone on the network path between '
            'this device and the server.',
            style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use SFTP or FTPS instead whenever the server supports it.',
            style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.errorContainer, foregroundColor: AppColors.onErrorContainer),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return result ?? false;
}
