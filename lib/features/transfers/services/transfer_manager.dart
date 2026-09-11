import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/transfer_item.dart';

/// Tracks in-flight and historical transfers app-wide (the badge count in
/// the top bar, and the Transfers tab, both read from this).
abstract interface class TransferManager extends ChangeNotifier {
  List<TransferItem> get transfers;
  int get activeCount;

  String enqueue({
    required String filename,
    required TransferDirection direction,
    required int totalBytes,
  });

  /// Registers a transfer driven by an EXTERNAL real operation (a real
  /// SFTP upload/download in progress) rather than the manager's own
  /// simulated ticking — see `SftpScreen`'s download/upload flows. The
  /// caller is responsible for calling [updateProgress] and
  /// [completeTransfer]/[failTransfer] as the real operation proceeds.
  String registerExternalTransfer({
    required String filename,
    required TransferDirection direction,
    required int totalBytes,
  });

  void updateProgress(String id, int transferredBytes, {double speedBytesPerSec = 0});
  void completeTransfer(String id);
  void failTransfer(String id, String error);

  void pause(String id);
  void resume(String id);
  void cancel(String id);
  void retry(String id);
  void clearCompleted();
}

/// Mock manager: enqueued transfers "run" on a timer with a randomized
/// speed, no real bytes move anywhere. Clearly a simulation — screens
/// built on this must not claim a real upload/download succeeded.
class MockTransferManager extends ChangeNotifier implements TransferManager {
  final List<TransferItem> _transfers = [];
  final Map<String, Timer> _timers = {};
  int _nextId = 1;

  MockTransferManager() {
    // Seed two in-flight transfers so the Transfers tab has something to
    // show immediately, matching the "2" badge count in the Stitch header.
    _seedTransfer('backup_20250218.tar.gz', TransferDirection.download, 245 * 1024 * 1024, 96 * 1024 * 1024);
    _seedTransfer('site-release-v4.zip', TransferDirection.upload, 58 * 1024 * 1024, 12 * 1024 * 1024);
  }

  void _seedTransfer(String name, TransferDirection dir, int total, int transferred) {
    final id = 'xfer-${_nextId++}';
    _transfers.add(TransferItem(
      id: id,
      filename: name,
      direction: dir,
      totalBytes: total,
      transferredBytes: transferred,
      status: TransferStatus.running,
      speedBytesPerSec: 1.2 * 1024 * 1024,
    ));
    _startTicking(id);
  }

  @override
  List<TransferItem> get transfers => List.unmodifiable(_transfers);

  @override
  int get activeCount =>
      _transfers.where((t) => t.status == TransferStatus.running || t.status == TransferStatus.queued).length;

  @override
  String enqueue({required String filename, required TransferDirection direction, required int totalBytes}) {
    final id = 'xfer-${_nextId++}';
    _transfers.insert(
      0,
      TransferItem(
        id: id,
        filename: filename,
        direction: direction,
        totalBytes: totalBytes,
        transferredBytes: 0,
        status: TransferStatus.queued,
      ),
    );
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 400), () => _startTicking(id));
    return id;
  }

  void _startTicking(String id) {
    _timers[id]?.cancel();
    _timers[id] = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final index = _transfers.indexWhere((t) => t.id == id);
      if (index == -1) {
        timer.cancel();
        return;
      }
      final t = _transfers[index];
      if (t.status != TransferStatus.running && t.status != TransferStatus.queued) {
        timer.cancel();
        return;
      }
      final speed = (0.8 + (id.hashCode % 5) * 0.3) * 1024 * 1024;
      final nextTransferred = (t.transferredBytes + speed * 0.5).clamp(0, t.totalBytes).toInt();
      final done = nextTransferred >= t.totalBytes;
      _transfers[index] = t.copyWith(
        transferredBytes: nextTransferred,
        status: done ? TransferStatus.completed : TransferStatus.running,
        speedBytesPerSec: done ? 0 : speed,
      );
      notifyListeners();
      if (done) timer.cancel();
    });
  }

  @override
  String registerExternalTransfer({
    required String filename,
    required TransferDirection direction,
    required int totalBytes,
  }) {
    final id = 'xfer-${_nextId++}';
    _transfers.insert(
      0,
      TransferItem(
        id: id,
        filename: filename,
        direction: direction,
        totalBytes: totalBytes,
        transferredBytes: 0,
        status: TransferStatus.running,
      ),
    );
    notifyListeners();
    return id;
  }

  @override
  void updateProgress(String id, int transferredBytes, {double speedBytesPerSec = 0}) {
    final index = _transfers.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _transfers[index] = _transfers[index].copyWith(
      transferredBytes: transferredBytes,
      speedBytesPerSec: speedBytesPerSec,
      status: TransferStatus.running,
    );
    notifyListeners();
  }

  @override
  void completeTransfer(String id) {
    final index = _transfers.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _transfers[index] = _transfers[index].copyWith(status: TransferStatus.completed);
    notifyListeners();
  }

  @override
  void failTransfer(String id, String error) {
    final index = _transfers.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _transfers[index] = _transfers[index].copyWith(status: TransferStatus.failed, error: error);
    notifyListeners();
  }

  @override
  void pause(String id) => _updateStatus(id, TransferStatus.paused);

  @override
  void resume(String id) {
    _updateStatus(id, TransferStatus.running);
    _startTicking(id);
  }

  @override
  void cancel(String id) {
    _timers[id]?.cancel();
    _updateStatus(id, TransferStatus.cancelled);
  }

  @override
  void retry(String id) {
    final index = _transfers.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _transfers[index] = _transfers[index].copyWith(status: TransferStatus.queued, transferredBytes: 0, error: null);
    notifyListeners();
    _startTicking(id);
  }

  @override
  void clearCompleted() {
    _transfers.removeWhere((t) =>
        t.status == TransferStatus.completed || t.status == TransferStatus.cancelled);
    notifyListeners();
  }

  void _updateStatus(String id, TransferStatus status) {
    final index = _transfers.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _transfers[index] = _transfers[index].copyWith(status: status);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}
