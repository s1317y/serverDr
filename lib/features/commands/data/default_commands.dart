import '../models/command_shortcut.dart';

/// Built-in command shortcuts, covering every category the brief calls
/// out. This seeds the command palette; a future phase can let users add
/// their own alongside these.
const List<CommandShortcut> kDefaultCommands = [
  // System
  CommandShortcut(
    name: 'System info',
    command: 'uname -a',
    description: 'Kernel, hostname and architecture',
    category: CommandCategory.system,
  ),
  CommandShortcut(
    name: 'Uptime',
    command: 'uptime',
    description: 'How long the box has been running, plus load average',
    category: CommandCategory.system,
  ),
  CommandShortcut(
    name: 'Memory usage',
    command: 'free -h',
    description: 'Human-readable RAM and swap usage',
    category: CommandCategory.system,
  ),

  // Network
  CommandShortcut(
    name: 'Listening ports',
    command: 'ss -tulpn | grep LISTEN',
    description: 'Show all active TCP/UDP ports listening for connections',
    category: CommandCategory.network,
  ),
  CommandShortcut(
    name: 'IP addresses',
    command: 'ip addr',
    description: 'List network interfaces and their addresses',
    category: CommandCategory.network,
  ),

  // Processes
  CommandShortcut(
    name: 'Process list',
    command: 'ps aux',
    description: 'All running processes with resource usage',
    category: CommandCategory.processes,
  ),

  // Services
  CommandShortcut(
    name: 'Service status',
    command: 'systemctl status nginx',
    description: 'Check HTTP server daemon state and recent logs',
    category: CommandCategory.services,
  ),
  CommandShortcut(
    name: 'Restart service',
    command: 'systemctl restart nginx',
    description: 'Restart the nginx service',
    category: CommandCategory.services,
    dangerous: true,
  ),

  // Nginx
  CommandShortcut(
    name: 'Test nginx config',
    command: 'nginx -t',
    description: 'Validate nginx configuration syntax before reloading',
    category: CommandCategory.nginx,
  ),

  // Apache
  CommandShortcut(
    name: 'Test Apache config',
    command: 'apachectl configtest',
    description: 'Validate Apache configuration syntax',
    category: CommandCategory.apache,
  ),

  // Docker
  CommandShortcut(
    name: 'List containers',
    command: 'docker ps',
    description: 'Running containers, status, and exposed ports',
    category: CommandCategory.docker,
  ),
  CommandShortcut(
    name: 'Container stats',
    command: 'docker stats --no-stream',
    description: 'Snapshot CPU, memory and I/O of all running containers',
    category: CommandCategory.docker,
  ),
  CommandShortcut(
    name: 'Container logs',
    command: 'docker logs -f',
    description: 'Follow logs for a container (append the name/ID)',
    category: CommandCategory.docker,
  ),

  // Files
  CommandShortcut(
    name: 'Directory sizes',
    command: 'du -sh *',
    description: 'Human-readable size of each item in the current folder',
    category: CommandCategory.files,
  ),

  // Disk
  CommandShortcut(
    name: 'Disk usage',
    command: 'df -h --total',
    description: 'Human-readable disk partition consumption',
    category: CommandCategory.disk,
  ),

  // Logs
  CommandShortcut(
    name: 'System journal',
    command: 'journalctl -u nginx -n 50 --no-pager',
    description: 'Dump last 50 lines of the systemd journal for nginx',
    category: CommandCategory.logs,
  ),
  CommandShortcut(
    name: 'Tail access log',
    command: 'tail -f /var/log/nginx/access.log',
    description: 'Stream live incoming reverse-proxy traffic',
    category: CommandCategory.logs,
  ),
];
