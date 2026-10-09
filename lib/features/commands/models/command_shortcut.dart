import 'package:flutter/foundation.dart';

enum CommandCategory {
  system,
  cpuMemory,
  disk,
  files,
  network,
  processes,
  services,
  nginx,
  apache,
  php,
  docker,
  database,
  security,
  logs,
  users,
  permissions,
  ssh,
  git,
  cron,
  systemd,
  packageManagement,
  archives,
  diagnostics,
  kernel,
  dns,
  sslTls;

  String get label => switch (this) {
        CommandCategory.system => 'System',
        CommandCategory.cpuMemory => 'CPU / Memory',
        CommandCategory.disk => 'Disk',
        CommandCategory.files => 'Files',
        CommandCategory.network => 'Network',
        CommandCategory.processes => 'Processes',
        CommandCategory.services => 'Services',
        CommandCategory.nginx => 'Nginx',
        CommandCategory.apache => 'Apache',
        CommandCategory.php => 'PHP',
        CommandCategory.docker => 'Docker',
        CommandCategory.database => 'Database',
        CommandCategory.security => 'Security',
        CommandCategory.logs => 'Logs',
        CommandCategory.users => 'Users',
        CommandCategory.permissions => 'Permissions',
        CommandCategory.ssh => 'SSH',
        CommandCategory.git => 'Git',
        CommandCategory.cron => 'Cron',
        CommandCategory.systemd => 'Systemd',
        CommandCategory.packageManagement => 'Package Mgmt',
        CommandCategory.archives => 'Archives',
        CommandCategory.diagnostics => 'Diagnostics',
        CommandCategory.kernel => 'Kernel',
        CommandCategory.dns => 'DNS',
        CommandCategory.sslTls => 'SSL/TLS',
      };
}

/// A saved/quick-access shell command shown in the terminal's command
/// palette. [dangerous] commands must be confirmed before running — see
/// `DangerousCommandDialog`.
///
/// PARAMETERIZED COMMANDS: [command] may contain `{placeholder}` tokens
/// (e.g. `systemctl status {service}`) — see [placeholders]. The palette
/// prompts for each one and substitutes it before handing the command
/// back to the terminal; nothing runs with a literal `{...}` in it.
@immutable
class CommandShortcut {
  const CommandShortcut({
    required this.name,
    required this.command,
    required this.description,
    required this.category,
    this.dangerous = false,
  });

  final String name;
  final String command;
  final String description;
  final CommandCategory category;
  final bool dangerous;

  /// Stable-enough identity for favorites/recent persistence, derived
  /// from category+name rather than a manually-assigned field — so the
  /// large static command list doesn't need per-entry bookkeeping.
  String get id => '${category.name}.${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

  static final RegExp _placeholderPattern = RegExp(r'\{(\w+)\}');

  /// Placeholder names found in [command], in order, e.g. `['service']`
  /// for `systemctl status {service}`. Empty for ordinary commands.
  List<String> get placeholders =>
      _placeholderPattern.allMatches(command).map((m) => m.group(1)!).toSet().toList();

  bool get isParameterized => placeholders.isNotEmpty;

  /// Substitutes each `{name}` in [command] with `values[name]`.
  String resolve(Map<String, String> values) {
    return command.replaceAllMapped(_placeholderPattern, (m) => values[m.group(1)!] ?? m.group(0)!);
  }
}
