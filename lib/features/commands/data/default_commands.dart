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

  // ---------------------------------------------------------------
  // Parameterized commands — prompt for a value before running.
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Service Status',
    command: 'systemctl status {service}',
    description: 'Check the status of a specific service by name',
    category: CommandCategory.services,
  ),
  CommandShortcut(
    name: 'Restart Service',
    command: 'systemctl restart {service}',
    description: 'Restart a specific service by name',
    category: CommandCategory.services,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'View Service Log',
    command: 'journalctl -u {service} -n 100 --no-pager',
    description: 'Last 100 journal lines for a specific service',
    category: CommandCategory.logs,
  ),
  CommandShortcut(
    name: 'Find Recently Changed Files',
    command: 'find {path} -type f -mtime -{days}',
    description: 'Files modified in the last N days under a path',
    category: CommandCategory.files,
  ),
  CommandShortcut(
    name: 'Grep in Path',
    command: "grep -r '{pattern}' {path}",
    description: 'Search for a text pattern recursively under a path',
    category: CommandCategory.files,
  ),
  CommandShortcut(
    name: 'Tail a File',
    command: 'tail -f -n 100 {path}',
    description: 'Follow the end of a specific log or file',
    category: CommandCategory.logs,
  ),
  CommandShortcut(
    name: 'Kill by PID',
    command: 'kill -9 {pid}',
    description: 'Force-terminate a specific process',
    category: CommandCategory.processes,
    dangerous: true,
  ),
  CommandShortcut(
    name: 'Container Logs',
    command: 'docker logs -f --tail 200 {container}',
    description: 'Follow logs for a specific container',
    category: CommandCategory.docker,
  ),
  CommandShortcut(
    name: 'Container Shell',
    command: 'docker exec -it {container} /bin/bash',
    description: 'Attach an interactive shell inside a specific container',
    category: CommandCategory.docker,
  ),
  CommandShortcut(
    name: 'Check DNS Record',
    command: 'dig {domain}',
    description: 'Resolve a specific domain\'s DNS records',
    category: CommandCategory.dns,
  ),
  CommandShortcut(
    name: 'Check Certificate Expiry',
    command: 'echo | openssl s_client -connect {domain}:443 -servername {domain} 2>/dev/null | openssl x509 -noout -dates',
    description: 'Show a specific domain\'s TLS certificate validity dates',
    category: CommandCategory.sslTls,
  ),

  // ---------------------------------------------------------------
  // CPU / Memory (dedicated deep-dive category)
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Virtual memory stats',
    command: 'vmstat 1 5',
    description: 'Kernel threads, memory, paging and CPU activity over 5 samples',
    category: CommandCategory.cpuMemory,
  ),
  CommandShortcut(
    name: 'Per-core CPU usage',
    command: 'mpstat -P ALL 1 3',
    description: 'Per-core CPU utilization (needs sysstat)',
    category: CommandCategory.cpuMemory,
  ),
  CommandShortcut(
    name: 'Memory map summary',
    command: 'cat /proc/meminfo',
    description: 'Full raw kernel memory accounting',
    category: CommandCategory.cpuMemory,
  ),
  CommandShortcut(
    name: 'NUMA memory layout',
    command: 'numactl --hardware',
    description: 'NUMA node memory distribution, if applicable',
    category: CommandCategory.cpuMemory,
  ),

  // ---------------------------------------------------------------
  // PHP
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'PHP version',
    command: 'php -v',
    description: 'Installed PHP version and build info',
    category: CommandCategory.php,
  ),
  CommandShortcut(
    name: 'Loaded PHP modules',
    command: 'php -m',
    description: 'List all loaded PHP extensions',
    category: CommandCategory.php,
  ),
  CommandShortcut(
    name: 'PHP config values',
    command: 'php --ini',
    description: 'Show which php.ini files are loaded',
    category: CommandCategory.php,
  ),
  CommandShortcut(
    name: 'PHP-FPM status',
    command: 'systemctl status php-fpm* 2>/dev/null || systemctl status php*-fpm',
    description: 'Check PHP-FPM service state (name varies by distro/version)',
    category: CommandCategory.php,
  ),

  // ---------------------------------------------------------------
  // Database
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'MySQL/MariaDB status',
    command: 'systemctl status mysql 2>/dev/null || systemctl status mariadb',
    description: 'Check MySQL or MariaDB service state',
    category: CommandCategory.database,
  ),
  CommandShortcut(
    name: 'PostgreSQL status',
    command: 'systemctl status postgresql',
    description: 'Check PostgreSQL service state',
    category: CommandCategory.database,
  ),
  CommandShortcut(
    name: 'Database processes',
    command: "ps aux | grep -E 'mysqld|postgres|mongod|redis-server'",
    description: 'Running database server processes',
    category: CommandCategory.database,
  ),
  CommandShortcut(
    name: 'Database listening ports',
    command: 'ss -tulpn | grep -E ":3306|:5432|:27017|:6379"',
    description: 'Common database ports currently listening',
    category: CommandCategory.database,
  ),

  // ---------------------------------------------------------------
  // Security
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Logged in users',
    command: 'who',
    description: 'Who is currently logged into this server',
    category: CommandCategory.security,
  ),
  CommandShortcut(
    name: 'Login history',
    command: 'last -20',
    description: 'Last 20 login sessions',
    category: CommandCategory.security,
  ),
  CommandShortcut(
    name: 'Last log failures',
    command: 'lastlog',
    description: 'Most recent login per user, including never-logged-in accounts',
    category: CommandCategory.security,
  ),
  CommandShortcut(
    name: 'Find SUID binaries',
    command: 'find / -perm -4000 -type f 2>/dev/null',
    description: 'Binaries that run with owner (often root) privileges regardless of caller',
    category: CommandCategory.security,
  ),
  CommandShortcut(
    name: 'Find SGID binaries',
    command: 'find / -perm -2000 -type f 2>/dev/null',
    description: 'Binaries that run with group privileges regardless of caller',
    category: CommandCategory.security,
  ),
  CommandShortcut(
    name: 'Find world-writable files',
    command: 'find / -xdev -type f -perm -0002 2>/dev/null',
    description: 'Files any local user can modify — review unexpected ones',
    category: CommandCategory.security,
  ),
  CommandShortcut(
    name: 'Inspect authorized_keys',
    command: 'cat ~/.ssh/authorized_keys 2>/dev/null',
    description: 'SSH public keys authorized for the current user',
    category: CommandCategory.security,
  ),

  // ---------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Current user ID',
    command: 'id',
    description: 'UID/GID and group memberships of the current user',
    category: CommandCategory.users,
  ),
  CommandShortcut(
    name: 'All system users',
    command: 'getent passwd',
    description: 'Full list of local user accounts',
    category: CommandCategory.users,
  ),
  CommandShortcut(
    name: 'All system groups',
    command: 'getent group',
    description: 'Full list of local groups',
    category: CommandCategory.users,
  ),
  CommandShortcut(
    name: 'Current user\'s groups',
    command: 'groups',
    description: 'Groups the current user belongs to',
    category: CommandCategory.users,
  ),
  CommandShortcut(
    name: 'Who is logged in (verbose)',
    command: 'w',
    description: 'Logged-in users and what they\'re running',
    category: CommandCategory.users,
  ),

  // ---------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Long listing with permissions',
    command: 'ls -lah',
    description: 'Detailed file listing including hidden files',
    category: CommandCategory.permissions,
  ),
  CommandShortcut(
    name: 'File status details',
    command: 'stat',
    description: 'Detailed metadata for a file (append path)',
    category: CommandCategory.permissions,
  ),
  CommandShortcut(
    name: 'Resolve path permissions',
    command: 'namei -l',
    description: 'Show permissions of every component in a path (append path)',
    category: CommandCategory.permissions,
  ),

  // ---------------------------------------------------------------
  // SSH
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'SSH client version',
    command: 'ssh -V',
    description: 'Installed OpenSSH version',
    category: CommandCategory.ssh,
  ),
  CommandShortcut(
    name: 'Effective sshd config',
    command: 'sshd -T 2>/dev/null | head -40',
    description: 'Resolved SSH daemon configuration (includes + defaults applied)',
    category: CommandCategory.ssh,
  ),
  CommandShortcut(
    name: 'sshd service status',
    command: 'systemctl status sshd 2>/dev/null || systemctl status ssh',
    description: 'Check the SSH daemon service state',
    category: CommandCategory.ssh,
  ),

  // ---------------------------------------------------------------
  // Git
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Git status',
    command: 'git status',
    description: 'Working tree status for the repo in the current directory',
    category: CommandCategory.git,
  ),
  CommandShortcut(
    name: 'Git branches',
    command: 'git branch -a',
    description: 'List local and remote branches',
    category: CommandCategory.git,
  ),
  CommandShortcut(
    name: 'Git recent log',
    command: 'git log --oneline -20',
    description: 'Last 20 commits, one line each',
    category: CommandCategory.git,
  ),
  CommandShortcut(
    name: 'Git remotes',
    command: 'git remote -v',
    description: 'Configured remotes for the current repo',
    category: CommandCategory.git,
  ),

  // ---------------------------------------------------------------
  // Cron
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Current user\'s crontab',
    command: 'crontab -l',
    description: 'Scheduled cron jobs for the current user',
    category: CommandCategory.cron,
  ),
  CommandShortcut(
    name: 'System-wide cron jobs',
    command: 'cat /etc/crontab; ls /etc/cron.d/',
    description: 'System crontab and drop-in cron.d files',
    category: CommandCategory.cron,
  ),
  CommandShortcut(
    name: 'Systemd timers',
    command: 'systemctl list-timers --all',
    description: 'Systemd timer units (a common cron alternative)',
    category: CommandCategory.cron,
  ),

  // ---------------------------------------------------------------
  // Systemd
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'All units',
    command: 'systemctl list-units --all',
    description: 'Every loaded systemd unit and its state',
    category: CommandCategory.systemd,
  ),
  CommandShortcut(
    name: 'Failed units',
    command: 'systemctl --failed',
    description: 'Units that failed to start',
    category: CommandCategory.systemd,
  ),
  CommandShortcut(
    name: 'Daemon reload',
    command: 'systemctl daemon-reload',
    description: 'Reload unit files after editing one manually',
    category: CommandCategory.systemd,
    dangerous: true,
  ),

  // ---------------------------------------------------------------
  // Package management
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'APT update check',
    command: 'apt list --upgradable 2>/dev/null',
    description: 'Packages with available updates (Debian/Ubuntu)',
    category: CommandCategory.packageManagement,
  ),
  CommandShortcut(
    name: 'APT history',
    command: 'cat /var/log/apt/history.log | tail -50',
    description: 'Recent apt install/remove/upgrade history',
    category: CommandCategory.packageManagement,
  ),
  CommandShortcut(
    name: 'DNF update check',
    command: 'dnf check-update',
    description: 'Packages with available updates (Fedora/RHEL/Rocky/Alma)',
    category: CommandCategory.packageManagement,
  ),
  CommandShortcut(
    name: 'DNF history',
    command: 'dnf history',
    description: 'Recent dnf transaction history',
    category: CommandCategory.packageManagement,
  ),
  CommandShortcut(
    name: 'APK installed packages',
    command: 'apk info',
    description: 'List installed packages (Alpine)',
    category: CommandCategory.packageManagement,
  ),
  CommandShortcut(
    name: 'List installed packages (dpkg)',
    command: 'dpkg -l | head -50',
    description: 'Installed packages via dpkg (Debian/Ubuntu)',
    category: CommandCategory.packageManagement,
  ),

  // ---------------------------------------------------------------
  // Archives
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Create tar.gz',
    command: 'tar -czvf archive.tar.gz {path}',
    description: 'Compress a folder into a gzip tarball',
    category: CommandCategory.archives,
  ),
  CommandShortcut(
    name: 'Extract tar.gz',
    command: 'tar -xzvf {path}',
    description: 'Extract a gzip tarball in the current directory',
    category: CommandCategory.archives,
  ),
  CommandShortcut(
    name: 'Zip a folder',
    command: 'zip -r archive.zip {path}',
    description: 'Compress a folder into a zip archive',
    category: CommandCategory.archives,
  ),
  CommandShortcut(
    name: 'Unzip an archive',
    command: 'unzip {path}',
    description: 'Extract a zip archive in the current directory',
    category: CommandCategory.archives,
  ),

  // ---------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Kernel ring buffer',
    command: 'dmesg -T | tail -100',
    description: 'Recent kernel messages, human-readable timestamps',
    category: CommandCategory.diagnostics,
  ),
  CommandShortcut(
    name: 'System load + I/O snapshot',
    command: 'vmstat 1 5',
    description: 'Combined CPU/memory/IO snapshot over 5 samples',
    category: CommandCategory.diagnostics,
  ),
  CommandShortcut(
    name: 'Disk I/O stats',
    command: 'iostat -x 1 3',
    description: 'Per-device throughput and latency (needs sysstat)',
    category: CommandCategory.diagnostics,
  ),
  CommandShortcut(
    name: 'Open file descriptors count',
    command: 'lsof | wc -l',
    description: 'Total open file descriptors system-wide',
    category: CommandCategory.diagnostics,
  ),

  // ---------------------------------------------------------------
  // Kernel
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'Kernel version',
    command: 'uname -r',
    description: 'Running kernel version',
    category: CommandCategory.kernel,
  ),
  CommandShortcut(
    name: 'Loaded kernel modules',
    command: 'lsmod | head -30',
    description: 'Currently loaded kernel modules',
    category: CommandCategory.kernel,
  ),
  CommandShortcut(
    name: 'Kernel parameters',
    command: 'sysctl -a 2>/dev/null | head -50',
    description: 'Runtime kernel tunables',
    category: CommandCategory.kernel,
  ),

  // ---------------------------------------------------------------
  // DNS
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'DNS lookup',
    command: 'dig google.com',
    description: 'Example DNS resolution — edit the domain before running',
    category: CommandCategory.dns,
  ),
  CommandShortcut(
    name: 'Reverse DNS / nslookup',
    command: 'nslookup',
    description: 'Interactive/one-shot DNS lookup tool (append a host)',
    category: CommandCategory.dns,
  ),
  CommandShortcut(
    name: 'Resolver configuration',
    command: 'cat /etc/resolv.conf',
    description: 'Which DNS servers this host is configured to use',
    category: CommandCategory.dns,
  ),

  // ---------------------------------------------------------------
  // SSL/TLS
  // ---------------------------------------------------------------
  CommandShortcut(
    name: 'OpenSSL version',
    command: 'openssl version',
    description: 'Installed OpenSSL version',
    category: CommandCategory.sslTls,
  ),
  CommandShortcut(
    name: 'Inspect a local cert file',
    command: 'openssl x509 -in {path} -noout -text',
    description: 'Show full details of a certificate file on disk',
    category: CommandCategory.sslTls,
  ),
];
