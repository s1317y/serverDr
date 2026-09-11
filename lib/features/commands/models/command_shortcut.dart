import 'package:flutter/foundation.dart';

enum CommandCategory {
  system,
  network,
  processes,
  services,
  nginx,
  apache,
  docker,
  files,
  disk,
  logs;

  String get label => switch (this) {
        CommandCategory.system => 'System',
        CommandCategory.network => 'Network',
        CommandCategory.processes => 'Processes',
        CommandCategory.services => 'Services',
        CommandCategory.nginx => 'Nginx',
        CommandCategory.apache => 'Apache',
        CommandCategory.docker => 'Docker',
        CommandCategory.files => 'Files',
        CommandCategory.disk => 'Disk',
        CommandCategory.logs => 'Logs',
      };
}

/// A saved/quick-access shell command shown in the terminal's command
/// palette. [dangerous] commands must be confirmed before running — see
/// `DangerousCommandDialog`.
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
}
