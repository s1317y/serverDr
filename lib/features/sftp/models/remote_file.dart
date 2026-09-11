import 'package:flutter/foundation.dart';

/// Small "chip" badges shown next to a filename in the Stitch file rows —
/// `LIVE` (folder with recent activity), `ACTIVE` (currently open in the
/// editor), `SECURE` (sensitive/locked-down permissions).
enum RemoteEntryBadge { none, live, active, secure }

/// One file or directory entry in a remote listing.
@immutable
class RemoteFile {
  const RemoteFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.permissions,
    required this.modifiedAt,
    this.sizeBytes,
    this.itemCount,
    this.badge = RemoteEntryBadge.none,
    this.typeLabel,
  });

  final String name;

  /// Full remote path, e.g. `/var/www/html/nginx.conf`.
  final String path;
  final bool isDirectory;

  /// Unix permission string, e.g. `drwxr-xr-x` or `0644`.
  final String permissions;

  final DateTime modifiedAt;

  /// Set for files only.
  final int? sizeBytes;

  /// Set for directories only.
  final int? itemCount;

  final RemoteEntryBadge badge;

  /// Short uppercase type chip, e.g. `YML`, `GZ`, `HTML` — null for plain
  /// files with no special chip in the Stitch design.
  final String? typeLabel;
}

/// A listed directory: its entries plus the storage-quota gauge shown at
/// the top of the Stitch file manager screen.
@immutable
class RemoteDirectory {
  const RemoteDirectory({
    required this.path,
    required this.entries,
    required this.usedBytes,
    required this.totalBytes,
  });

  final String path;
  final List<RemoteFile> entries;
  final int usedBytes;
  final int totalBytes;

  double get usedFraction => totalBytes == 0 ? 0 : usedBytes / totalBytes;

  List<String> get pathSegments =>
      path == '/' ? const [] : path.split('/').where((s) => s.isNotEmpty).toList();
}
