import '../../../core/errors/app_failure.dart';
import '../../connections/models/connection_profile.dart';
import '../../ssh/models/host_key_verification.dart';
import '../../ssh/services/ssh_service.dart';
import '../models/server_health.dart';
import 'health_service.dart';

/// Real [HealthService]: runs a batch of read-only, POSIX-portable
/// commands over the shared SSH connection (`SshService.runCommand`) and
/// parses each result independently, so one missing tool (no `systemctl`,
/// no `docker`, a locked-down `/proc`) degrades that one section to
/// "Unavailable" rather than failing the whole snapshot.
///
/// Nothing here assumes systemd, Docker, or a specific package manager —
/// every collector is wrapped so a command that doesn't exist or is
/// denied just produces [CollectionState.unavailable] /
/// [CollectionState.permissionDenied] for that field.
class RealHealthService implements HealthService {
  RealHealthService(this._sshService);

  final SshService _sshService;

  Future<String?> _run(ConnectionProfile profile, String command, HostKeyDecisionHandler onHostKeyVerification) async {
    try {
      return await _sshService.runCommand(profile, command, onHostKeyVerification: onHostKeyVerification);
    } on AppFailure {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ServerHealth> collect(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
  }) async {
    Future<String?> run(String cmd) => _run(profile, cmd, onHostKeyVerification);

    final results = await Future.wait([
      run('cat /etc/hostname 2>/dev/null; echo ---; cat /etc/os-release 2>/dev/null; echo ---; uname -sr; echo ---; uname -m; echo ---; cat /proc/uptime'),
      run('nproc; echo ---; cat /proc/loadavg; echo ---; grep -m1 "model name" /proc/cpuinfo'),
      run('cat /proc/meminfo'),
      run('df -k -P 2>/dev/null'),
      run('df -i -P 2>/dev/null'),
      run('ps -eo pid,user,pcpu,pmem,comm --sort=-pcpu --no-headers 2>/dev/null | head -30'),
      run('systemctl list-units --type=service --state=running --no-legend --plain 2>/dev/null'),
      run('ip -o addr show 2>/dev/null'),
      run('command -v docker'),
    ]);

    final systemRaw = results[0];
    final cpuRaw = results[1];
    final memRaw = results[2];
    final dfRaw = results[3];
    final dfiRaw = results[4];
    final psRaw = results[5];
    final servicesRaw = results[6];
    final ipRaw = results[7];
    final dockerRaw = results[8];

    return ServerHealth(
      system: _parseSystem(systemRaw),
      cpu: _parseCpu(cpuRaw),
      memory: _parseMemory(memRaw),
      filesystems: _parseFilesystems(dfRaw, dfiRaw),
      processes: _parseProcesses(psRaw),
      services: _parseServices(servicesRaw),
      network: _parseNetwork(ipRaw),
      dockerAvailable: (dockerRaw ?? '').trim().isNotEmpty,
      lastUpdated: DateTime.now(),
    );
  }

  Collected<SystemInfo> _parseSystem(String? raw) {
    if (raw == null) return const Collected.unavailable();
    final parts = raw.split('---\n');
    if (parts.length < 5) return const Collected.unavailable();

    final hostname = parts[0].trim().isEmpty ? null : parts[0].trim();
    String? prettyName;
    for (final line in parts[1].split('\n')) {
      if (line.startsWith('PRETTY_NAME=')) {
        prettyName = line.substring('PRETTY_NAME='.length).replaceAll('"', '').trim();
      }
    }
    final kernel = parts[2].trim().isEmpty ? null : parts[2].trim();
    final arch = parts[3].trim().isEmpty ? null : parts[3].trim();
    final uptimeSeconds = double.tryParse(parts[4].trim().split(' ').first)?.round();

    return Collected.ok(SystemInfo(
      hostname: hostname,
      os: prettyName,
      kernel: kernel,
      architecture: arch,
      uptimeSeconds: uptimeSeconds,
    ));
  }

  Collected<CpuInfo> _parseCpu(String? raw) {
    if (raw == null) return const Collected.unavailable();
    final parts = raw.split('---\n');
    if (parts.isEmpty) return const Collected.unavailable();

    final coreCount = int.tryParse(parts[0].trim()) ?? 1;
    List<double>? loadAverage;
    if (parts.length > 1) {
      final loadParts = parts[1].trim().split(RegExp(r'\s+'));
      if (loadParts.length >= 3) {
        loadAverage = [
          double.tryParse(loadParts[0]) ?? 0,
          double.tryParse(loadParts[1]) ?? 0,
          double.tryParse(loadParts[2]) ?? 0,
        ];
      }
    }
    String? model;
    if (parts.length > 2) {
      final line = parts[2].trim();
      final idx = line.indexOf(':');
      if (idx != -1) model = line.substring(idx + 1).trim();
    }

    // NOTE: approximated from 1-minute load average relative to core
    // count, NOT a true busy-time sample (that would need two /proc/stat
    // reads with a delay between them, doubling round trips for every
    // refresh). Labelled as an approximation in the UI.
    final usage = loadAverage != null && coreCount > 0
        ? ((loadAverage[0] / coreCount) * 100).clamp(0, 100).toDouble()
        : 0.0;

    return Collected.ok(CpuInfo(usagePercent: usage, coreCount: coreCount, model: model, loadAverage: loadAverage));
  }

  Collected<MemoryInfo> _parseMemory(String? raw) {
    if (raw == null) return const Collected.unavailable();
    final values = <String, int>{};
    for (final line in raw.split('\n')) {
      final match = RegExp(r'^(\w+):\s+(\d+)\s*kB').firstMatch(line);
      if (match != null) {
        values[match.group(1)!] = int.parse(match.group(2)!);
      }
    }
    final total = values['MemTotal'];
    if (total == null) return const Collected.unavailable();
    final free = values['MemFree'] ?? 0;
    final available = values['MemAvailable'] ?? free;
    final used = total - available;

    return Collected.ok(MemoryInfo(
      totalKb: total,
      usedKb: used < 0 ? 0 : used,
      freeKb: free,
      availableKb: available,
      swapTotalKb: values['SwapTotal'],
      swapUsedKb: values.containsKey('SwapTotal') && values.containsKey('SwapFree')
          ? values['SwapTotal']! - values['SwapFree']!
          : null,
    ));
  }

  Collected<List<FilesystemInfo>> _parseFilesystems(String? dfRaw, String? dfiRaw) {
    if (dfRaw == null) return const Collected.unavailable();
    final inodesByMount = <String, (int, int)>{};
    if (dfiRaw != null) {
      for (final line in dfiRaw.split('\n').skip(1)) {
        final cols = line.trim().split(RegExp(r'\s+'));
        if (cols.length < 6) continue;
        final iTotal = int.tryParse(cols[1]);
        final iUsed = int.tryParse(cols[2]);
        if (iTotal != null && iUsed != null) {
          inodesByMount[cols.last] = (iTotal, iUsed);
        }
      }
    }

    final filesystems = <FilesystemInfo>[];
    for (final line in dfRaw.split('\n').skip(1)) {
      final cols = line.trim().split(RegExp(r'\s+'));
      if (cols.length < 6) continue;
      final total = int.tryParse(cols[1]);
      final used = int.tryParse(cols[2]);
      final avail = int.tryParse(cols[3]);
      if (total == null || used == null || avail == null) continue;
      final mount = cols.last;
      // Skip pseudo-filesystems that clutter the list without being
      // useful storage info.
      if (mount.startsWith('/dev') && mount != '/dev' ||
          mount.startsWith('/sys') ||
          mount.startsWith('/proc') ||
          mount.startsWith('/run') && total < 1024) {
        continue;
      }
      final inodes = inodesByMount[mount];
      filesystems.add(FilesystemInfo(
        filesystem: cols[0],
        mount: mount,
        totalKb: total,
        usedKb: used,
        availableKb: avail,
        inodesTotal: inodes?.$1,
        inodesUsed: inodes?.$2,
      ));
    }
    return Collected.ok(filesystems);
  }

  Collected<List<ProcessInfo>> _parseProcesses(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const Collected.unavailable();
    final processes = <ProcessInfo>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cols = trimmed.split(RegExp(r'\s+'));
      if (cols.length < 5) continue;
      final pid = int.tryParse(cols[0]);
      final cpu = double.tryParse(cols[2]);
      final mem = double.tryParse(cols[3]);
      if (pid == null || cpu == null || mem == null) continue;
      processes.add(ProcessInfo(
        pid: pid,
        user: cols[1],
        cpuPercent: cpu,
        memPercent: mem,
        command: cols.sublist(4).join(' '),
      ));
    }
    return Collected.ok(processes);
  }

  Collected<List<ServiceInfo>> _parseServices(String? raw) {
    if (raw == null) return const Collected.notSupported();
    final services = <ServiceInfo>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cols = trimmed.split(RegExp(r'\s+'));
      if (cols.isEmpty) continue;
      final name = cols[0].replaceAll('.service', '');
      services.add(ServiceInfo(name: name, active: true, stateLabel: 'running'));
    }
    return Collected.ok(services);
  }

  Collected<List<NetworkInterfaceInfo>> _parseNetwork(String? raw) {
    if (raw == null) return const Collected.unavailable();
    final byName = <String, List<String>>{};
    for (final line in raw.split('\n')) {
      final match = RegExp(r'^\d+:\s+(\S+?)(@\S+)?\s+inet6?\s+(\S+)').firstMatch(line.trim());
      if (match == null) continue;
      final name = match.group(1)!;
      final addr = match.group(3)!;
      byName.putIfAbsent(name, () => []).add(addr);
    }
    final interfaces = byName.entries.map((e) => NetworkInterfaceInfo(name: e.key, addresses: e.value)).toList();
    return Collected.ok(interfaces);
  }
}
