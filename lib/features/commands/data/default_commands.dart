import '../models/command_shortcut.dart';

/// Built-in command shortcut library. Expanded to be a genuinely useful
/// day-to-day reference across every category the app supports — not
/// just one example per category — so the palette is worth reaching for
/// instead of typing from memory.
const List<CommandShortcut> kDefaultCommands = [
  // ---------------------------------------------------------------
  // System
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'System info',
    command: 'uname -a',
    description: 'Kernel, hostname and architecture',
    category: CommandCategory.system,
  ),
  CommandShortcut(
    name: 'OS release',
    command: 'cat /etc/os-release',
    description: 'Distribution name and version',
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
  CommandShortcut(
    name: 'CPU info',
    command: 'lscpu',
    description: 'CPU model, core count, cache sizes',
    category: CommandCategory.system,
  ),
  CommandShortcut(
    name: 'Hostname / hardware',
    command: 'hostnamectl',
    description: 'Hostname, chassis, kernel and OS summary (systemd hosts)',
    category: CommandCategory.system,
  ),
  CommandShortcut(
    name: 'Current date/time',
    command: 'timedatectl',
    description: 'System clock, timezone and NTP sync status',
    category: CommandCategory.system,
  ),
  CommandShortcut(
    name: 'Environment variables',
    command: 'env',
    description: 'List all environment variables for this shell',
    category: CommandCategory.system,
  ),
  CommandShortcut(
    name: 'Reboot',
    command: 'reboot',
    description: 'Restart the server immediately',
    category: CommandCategory.system,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'Shutdown',
    command: 'shutdown -h now',
    description: 'Power off the server immediately',
    category: CommandCategory.system,
    dangerous: true,
  ),

  // ---------------------------------------------------------------
  // Network
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Listening ports',
    command: 'ss -tulpn',
    description: 'Show all active TCP/UDP ports listening for connections',
    category: CommandCategory.network,
  ),
  CommandShortcut(
    name: 'Active connections',
    command: 'ss -tanp',
    description: 'All established/active TCP connections with owning process',
    category: CommandCategory.network,
  ),
  CommandShortcut(
    name: 'IP addresses',
    command: 'ip addr',
    description: 'List network interfaces and their addresses',
    category: CommandCategory.network,
  ),
  CommandShortcut(
    name: 'Routing table',
    command: 'ip route',
    description: 'Show the kernel routing table',
    category: CommandCategory.network,
  ),
  CommandShortcut(
    name: 'DNS resolution test',
    command: 'getent hosts',
    description: 'Resolve a hostname via the system resolver (append a host)',
    category: CommandCategory.network,
  ),
  CommandShortcut(
    name: 'Ping test',
    command: 'ping -c 4 8.8.8.8',
    description: 'Basic outbound connectivity check',
    category: CommandCategory.network,
  ),
  CommandShortcut(
    name: 'Firewall rules (UFW)',
    command: 'ufw status verbose',
    description: 'Show active UFW firewall rules, if UFW is installed',
    category: CommandCategory.network,
  ),
  CommandShortcut(
    name: 'Firewall rules (iptables)',
    command: 'iptables -L -n -v',
    description: 'List active iptables rules with packet counters',
    category: CommandCategory.network,
  ),
  CommandShortcut(
    name: 'Bandwidth by connection',
    command: 'nload',
    description: 'Live incoming/outgoing traffic per interface (if installed)',
    category: CommandCategory.network,
  ),

  // ---------------------------------------------------------------
  // Processes
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Process list',
    command: 'ps aux',
    description: 'All running processes with resource usage',
    category: CommandCategory.processes,
  ),
  CommandShortcut(
    name: 'Process tree',
    command: 'ps auxf',
    description: 'Processes shown as a parent/child tree',
    category: CommandCategory.processes,
  ),
  CommandShortcut(
    name: 'Top by CPU',
    command: 'top -b -n 1 -o %CPU | head -20',
    description: 'One-shot snapshot of the top CPU-consuming processes',
    category: CommandCategory.processes,
  ),
  CommandShortcut(
    name: 'Top by memory',
    command: 'ps aux --sort=-%mem | head -20',
    description: 'Top memory-consuming processes',
    category: CommandCategory.processes,
  ),
  CommandShortcut(
    name: 'Find process by name',
    command: 'pgrep -a',
    description: 'List PIDs and command lines matching a name (append pattern)',
    category: CommandCategory.processes,
  ),
  CommandShortcut(
    name: 'Kill process',
    command: 'kill -9',
    description: 'Force-terminate a process (append PID)',
    category: CommandCategory.processes,
    dangerous: true,
  ),

  // ---------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'All service status',
    command: 'systemctl list-units --type=service --state=running',
    description: 'List every currently running systemd service',
    category: CommandCategory.services,
  ),
  CommandShortcut(
    name: 'Service status',
    command: 'systemctl status nginx',
    description: 'Check a specific service\'s state and recent logs',
    category: CommandCategory.services,
  ),
  CommandShortcut(
    name: 'Restart service',
    command: 'systemctl restart nginx',
    description: 'Restart a service',
    category: CommandCategory.services,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'Stop service',
    command: 'systemctl stop nginx',
    description: 'Stop a service',
    category: CommandCategory.services,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'Enable service on boot',
    command: 'systemctl enable nginx',
    description: 'Make a service start automatically on boot',
    category: CommandCategory.services,
  ),
  CommandShortcut(
    name: 'Failed services',
    command: 'systemctl --failed',
    description: 'List services that failed to start',
    category: CommandCategory.services,
  ),
  CommandShortcut(
    name: 'Cron jobs (current user)',
    command: 'crontab -l',
    description: 'List scheduled cron jobs for the current user',
    category: CommandCategory.services,
  ),
  CommandShortcut(
    name: 'Systemd timers',
    command: 'systemctl list-timers',
    description: 'List active systemd timers (cron alternative)',
    category: CommandCategory.services,
  ),

  // ---------------------------------------------------------------
  // Nginx
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Test nginx config',
    command: 'nginx -t',
    description: 'Validate nginx configuration syntax before reloading',
    category: CommandCategory.nginx,
  ),
  CommandShortcut(
    name: 'Reload nginx',
    command: 'systemctl reload nginx',
    description: 'Apply config changes without dropping connections',
    category: CommandCategory.nginx,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'Nginx version + modules',
    command: 'nginx -V',
    description: 'Show nginx build version and compiled-in modules',
    category: CommandCategory.nginx,
  ),
  CommandShortcut(
    name: 'Tail nginx access log',
    command: 'tail -f /var/log/nginx/access.log',
    description: 'Stream live incoming requests',
    category: CommandCategory.nginx,
  ),
  CommandShortcut(
    name: 'Tail nginx error log',
    command: 'tail -f /var/log/nginx/error.log',
    description: 'Stream live nginx errors',
    category: CommandCategory.nginx,
  ),

  // ---------------------------------------------------------------
  // Apache
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Test Apache config',
    command: 'apachectl configtest',
    description: 'Validate Apache configuration syntax',
    category: CommandCategory.apache,
  ),
  CommandShortcut(
    name: 'Reload Apache',
    command: 'systemctl reload apache2',
    description: 'Apply config changes without a full restart',
    category: CommandCategory.apache,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'List enabled modules',
    command: 'apache2ctl -M',
    description: 'Show currently loaded Apache modules',
    category: CommandCategory.apache,
  ),
  CommandShortcut(
    name: 'Tail Apache error log',
    command: 'tail -f /var/log/apache2/error.log',
    description: 'Stream live Apache errors',
    category: CommandCategory.apache,
  ),

  // ---------------------------------------------------------------
  // Docker
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'List containers',
    command: 'docker ps',
    description: 'Running containers, status, and exposed ports',
    category: CommandCategory.docker,
  ),
  CommandShortcut(
    name: 'List all containers',
    command: 'docker ps -a',
    description: 'Include stopped/exited containers',
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
    command: 'docker logs -f --tail 200',
    description: 'Follow the last 200 lines for a container (append name/ID)',
    category: CommandCategory.docker,
  ),
  CommandShortcut(
    name: 'List images',
    command: 'docker images',
    description: 'List locally pulled images and their sizes',
    category: CommandCategory.docker,
  ),
  CommandShortcut(
    name: 'List volumes',
    command: 'docker volume ls',
    description: 'List Docker-managed volumes',
    category: CommandCategory.docker,
  ),
  CommandShortcut(
    name: 'Compose up',
    command: 'docker compose up -d',
    description: 'Start services defined in docker-compose.yml, detached',
    category: CommandCategory.docker,
  ),
  CommandShortcut(
    name: 'Compose down',
    command: 'docker compose down',
    description: 'Stop and remove containers from the compose project',
    category: CommandCategory.docker,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'Restart container',
    command: 'docker restart',
    description: 'Restart a container (append name/ID)',
    category: CommandCategory.docker,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'Remove container',
    command: 'docker rm',
    description: 'Remove a stopped container (append name/ID)',
    category: CommandCategory.docker,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'Prune everything unused',
    command: 'docker system prune -a --volumes',
    description: 'Delete all unused containers, images, networks and volumes',
    category: CommandCategory.docker,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'Exec shell in container',
    command: 'docker exec -it',
    description: 'Attach an interactive shell (append container + /bin/bash)',
    category: CommandCategory.docker,
  ),

  // ---------------------------------------------------------------
  // Files
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Directory sizes',
    command: 'du -sh */ 2>/dev/null | sort -rh',
    description: 'Human-readable size of each folder here, largest first',
    category: CommandCategory.files,
  ),
  CommandShortcut(
    name: 'Find recently modified',
    command: "find . -mmin -60 -type f",
    description: 'Files modified in the last hour under the current path',
    category: CommandCategory.files,
  ),
  CommandShortcut(
    name: 'Find by name',
    command: 'find / -iname',
    description: 'Search the filesystem by filename (append pattern)',
    category: CommandCategory.files,
  ),
  CommandShortcut(
    name: 'Set permissions',
    command: 'chmod 644',
    description: 'Change file permissions (append path)',
    category: CommandCategory.files,
  ),
  CommandShortcut(
    name: 'Change ownership',
    command: 'chown www-data:www-data',
    description: 'Change file owner/group (append path)',
    category: CommandCategory.files,
  ),
  CommandShortcut(
    name: 'Archive a folder',
    command: 'tar -czvf archive.tar.gz',
    description: 'Create a gzip-compressed tarball (append source path)',
    category: CommandCategory.files,
  ),
  CommandShortcut(
    name: 'Remove recursively',
    command: 'rm -rf',
    description: 'Permanently delete a file or folder tree (append path)',
    category: CommandCategory.files,
    dangerous: true,
  ),

  // ---------------------------------------------------------------
  // Disk
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Disk usage',
    command: 'df -h --total',
    description: 'Human-readable disk partition consumption',
    category: CommandCategory.disk,
  ),
  CommandShortcut(
    name: 'Inode usage',
    command: 'df -i',
    description: 'Inode consumption per filesystem (a full-inode disk looks "fine" in df -h)',
    category: CommandCategory.disk,
  ),
  CommandShortcut(
    name: 'Block devices',
    command: 'lsblk',
    description: 'List disks and partitions as a tree',
    category: CommandCategory.disk,
  ),
  CommandShortcut(
    name: 'Disk I/O stats',
    command: 'iostat -x 1 3',
    description: 'Per-device read/write throughput and latency (needs sysstat)',
    category: CommandCategory.disk,
  ),
  CommandShortcut(
    name: 'Mounted filesystems',
    command: 'mount | column -t',
    description: 'List currently mounted filesystems and options',
    category: CommandCategory.disk,
  ),

  // ---------------------------------------------------------------
  // Logs
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'System journal (recent)',
    command: 'journalctl -n 100 --no-pager',
    description: 'Last 100 lines of the systemd journal',
    category: CommandCategory.logs,
  ),
  CommandShortcut(
    name: 'Journal for a unit',
    command: 'journalctl -u nginx -n 50 --no-pager',
    description: 'Last 50 lines of the journal for one service',
    category: CommandCategory.logs,
  ),
  CommandShortcut(
    name: 'Follow journal live',
    command: 'journalctl -f',
    description: 'Stream new journal entries as they happen',
    category: CommandCategory.logs,
  ),
  CommandShortcut(
    name: 'Kernel ring buffer',
    command: 'dmesg -T | tail -50',
    description: 'Recent kernel messages, human-readable timestamps',
    category: CommandCategory.logs,
  ),
  CommandShortcut(
    name: 'Auth log (Debian/Ubuntu)',
    command: 'tail -100 /var/log/auth.log',
    description: 'Recent SSH/sudo authentication events',
    category: CommandCategory.logs,
  ),
  CommandShortcut(
    name: 'Auth log (RHEL/CentOS)',
    command: 'tail -100 /var/log/secure',
    description: 'Recent SSH/sudo authentication events',
    category: CommandCategory.logs,
  ),
  CommandShortcut(
    name: 'Failed login attempts',
    command: "grep 'Failed password' /var/log/auth.log | tail -50",
    description: 'Recent failed SSH password attempts',
    category: CommandCategory.logs,
  ),
];
