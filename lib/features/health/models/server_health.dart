import 'package:flutter/foundation.dart';

/// Whether a piece of health data was actually collected, or the
/// collector couldn't get it — the UI must show these honestly rather
/// than a fake zero, per the brief ("show Unavailable / Not supported /
/// Permission denied rather than failing the entire Health screen").
enum CollectionState { ok, unavailable, notSupported, permissionDenied }

@immutable
class Collected<T> {
  const Collected.ok(T this.value) : state = CollectionState.ok;
  const Collected.unavailable()
      : value = null,
        state = CollectionState.unavailable;
  const Collected.notSupported()
      : value = null,
        state = CollectionState.notSupported;
  const Collected.permissionDenied()
      : value = null,
        state = CollectionState.permissionDenied;

  final T? value;
  final CollectionState state;

  bool get hasValue => state == CollectionState.ok && value != null;

  String get unavailableLabel => switch (state) {
        CollectionState.ok => '',
        CollectionState.unavailable => 'Unavailable',
        CollectionState.notSupported => 'Not supported',
        CollectionState.permissionDenied => 'Permission denied',
      };
}

@immutable
class CpuInfo {
  const CpuInfo({required this.usagePercent, required this.coreCount, required this.model, this.loadAverage});
  final double usagePercent;
  final int coreCount;
  final String? model;
  final List<double>? loadAverage;
}

@immutable
class MemoryInfo {
  const MemoryInfo({
    required this.totalKb,
    required this.usedKb,
    required this.freeKb,
    required this.availableKb,
    this.swapTotalKb,
    this.swapUsedKb,
  });
  final int totalKb;
  final int usedKb;
  final int freeKb;
  final int availableKb;
  final int? swapTotalKb;
  final int? swapUsedKb;

  double get usedFraction => totalKb == 0 ? 0 : usedKb / totalKb;
}

@immutable
class FilesystemInfo {
  const FilesystemInfo({
    required this.filesystem,
    required this.mount,
    required this.totalKb,
    required this.usedKb,
    required this.availableKb,
    this.inodesTotal,
    this.inodesUsed,
  });
  final String filesystem;
  final String mount;
  final int totalKb;
  final int usedKb;
  final int availableKb;
  final int? inodesTotal;
  final int? inodesUsed;

  double get usedFraction => totalKb == 0 ? 0 : usedKb / totalKb;
}

@immutable
class ProcessInfo {
  const ProcessInfo({
    required this.pid,
    required this.user,
    required this.cpuPercent,
    required this.memPercent,
    required this.command,
    this.parentPid,
    this.startTime,
  });
  final int pid;
  final String user;
  final double cpuPercent;
  final double memPercent;
  final String command;
  final int? parentPid;
  final String? startTime;
}

@immutable
class ServiceInfo {
  const ServiceInfo({required this.name, required this.active, required this.stateLabel, this.detail});
  final String name;
  final bool active;
  final String stateLabel; // e.g. "running", "stopped", "failed"
  final String? detail;
}

@immutable
class NetworkInterfaceInfo {
  const NetworkInterfaceInfo({required this.name, required this.addresses, this.rxBytesPerSec, this.txBytesPerSec});
  final String name;
  final List<String> addresses;
  final double? rxBytesPerSec;
  final double? txBytesPerSec;
}

/// The aggregate health snapshot — everything the Health screen renders.
/// Every field is a [Collected] wrapper except the ones that are
/// meaningless to collect partially (uptime/hostname/os/kernel/arch are
/// bundled into `SystemInfo` since a single `uname`/`/etc/os-release`
/// read either succeeds or doesn't).
@immutable
class SystemInfo {
  const SystemInfo({this.hostname, this.os, this.kernel, this.architecture, this.uptimeSeconds});
  final String? hostname;
  final String? os;
  final String? kernel;
  final String? architecture;
  final int? uptimeSeconds;
}

@immutable
class ServerHealth {
  const ServerHealth({
    required this.system,
    required this.cpu,
    required this.memory,
    required this.filesystems,
    required this.processes,
    required this.services,
    required this.network,
    required this.dockerAvailable,
    required this.lastUpdated,
  });

  final Collected<SystemInfo> system;
  final Collected<CpuInfo> cpu;
  final Collected<MemoryInfo> memory;
  final Collected<List<FilesystemInfo>> filesystems;
  final Collected<List<ProcessInfo>> processes;
  final Collected<List<ServiceInfo>> services;
  final Collected<List<NetworkInterfaceInfo>> network;
  final bool dockerAvailable;
  final DateTime lastUpdated;
}
