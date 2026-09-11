import 'package:flutter/foundation.dart';

enum TransferDirection { upload, download }

enum TransferStatus { queued, running, paused, completed, failed, cancelled }

/// One upload/download tracked by the Transfer Manager. This is the
/// concrete type referred to as "FileTransfer" in the SFTP architecture
/// section of the brief — kept here (rather than duplicated under
/// `features/sftp`) since FTP and future protocols share the exact same
/// shape.
@immutable
class TransferItem {
  const TransferItem({
    required this.id,
    required this.filename,
    required this.direction,
    required this.totalBytes,
    required this.transferredBytes,
    required this.status,
    this.speedBytesPerSec = 0,
    this.error,
  });

  final String id;
  final String filename;
  final TransferDirection direction;
  final int totalBytes;
  final int transferredBytes;
  final TransferStatus status;
  final double speedBytesPerSec;
  final String? error;

  double get progress => totalBytes == 0 ? 0 : transferredBytes / totalBytes;

  TransferItem copyWith({
    int? transferredBytes,
    TransferStatus? status,
    double? speedBytesPerSec,
    String? error,
  }) {
    return TransferItem(
      id: id,
      filename: filename,
      direction: direction,
      totalBytes: totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      status: status ?? this.status,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      error: error,
    );
  }
}
