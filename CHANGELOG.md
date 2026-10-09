# Changelog

All notable changes to ServerDr are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/).

## [0.1.0] - Android beta

First public beta. (Formerly developed under the name ServerKit.)

### Added
- Saved server connections with password and SSH private-key authentication
- Test Connection before saving; explicit connect/disconnect with real connection state
- SSH host-key verification (new host and changed host flows) and a Known SSH Hosts manager
- Real interactive SSH terminal (ANSI/VT100) with a mobile key bar
- Command palette: 146 commands, 26 categories, search, favorites, recent, parameterized and dangerous-command confirmation
- SFTP file manager: browse, upload, download, rename, create, recursive folder delete, per-item action menus
- Remote file editor with dirty-state tracking and a save/discard/cancel prompt
- Transfer manager with real upload/download progress
- In-app web browser with Hard Reload (No Cache)
- Server health: uptime, CPU load, memory, disk/inodes, processes, services, network
- Multi-server monitoring with per-server intervals, calculated status and honest freshness
- Security audit: authentication, listening ports, SSH config, users, persistence, file permissions, package activity, Docker
- Security finding details and JSON export
- Settings: UI scale, terminal and editor font size, theme selector

### Known limitations
- Android only; FTP/FTPS not implemented
- Light theme is not functional yet (renders as Dark)
- Monitoring only runs while the app process is alive (no background scheduling)
- No push notifications or alerting
- SFTP transfers are buffered in memory
- Log explorer, file-change diffing, web log analysis and custom security checks are not implemented