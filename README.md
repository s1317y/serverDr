# ServerDr

**Your server doctor.**

ServerDr is a mobile-first server administration, monitoring and security app for Android. Connect straight from your phone to your Linux servers over SSH and SFTP, with no account, no cloud backend and no telemetry.

> **Status: Android beta.** It has been tested on real Android devices against real Linux servers. Expect rough edges. See [Known limitations](#known-limitations).

<!-- Add screenshots here, e.g.:
<p align="center">
  <img src="docs/screenshots/terminal.png" width="220" />
  <img src="docs/screenshots/files.png" width="220" />
  <img src="docs/screenshots/health.png" width="220" />
  <img src="docs/screenshots/security.png" width="220" />
</p>
-->

## Features

### Connections
- Saved server profiles with password or SSH private-key authentication
- Private keys are chosen through the Android file picker (no pasting key text)
- **Test Connection** before saving
- Explicit connect and disconnect per server, with real connection state (Disconnected, Connecting, Connected, Reconnecting, Connection Failed, Authentication Failed, Host Verification Required)
- A saved server is never shown as connected unless it really is

### Terminal
- Real interactive SSH shell with full ANSI/VT100 support
- Mobile key bar: Ctrl+C/D/L/Z, Tab, Esc, arrows and common symbols
- Command palette with **146 commands across 26 categories**
  - Search, favorites and recent commands
  - Parameterized commands such as `systemctl status {service}`
  - Confirmation required for dangerous commands (reboot, `rm -rf`, `docker system prune` and similar)
  - Recent history skips anything that looks like it contains a secret

### Files (SFTP)
- Browse, open, upload, download, rename, create folders and files, delete (folders are deleted recursively)
- Per-item action menus for files and directories
- Remote text editor that reads and writes the real file
  - Unsaved-changes tracking and a Save / Discard / Cancel prompt on exit
  - Failed saves keep your edits and show the actual error
- Transfer manager with real progress for uploads and downloads

### Web
- In-app browser for your server's website
- Normal reload, plus **Hard Reload (No Cache)**, which clears the WebView cache and adds a cache-busting parameter
- Cookies are only cleared when you explicitly ask

### Health
- Health collected from inside the server over your existing SSH connection (not an external ping)
- Uptime, CPU load, memory, disk and inode usage, load average, top processes, services and network interfaces
- If one metric can't be collected (permissions, missing tools), the rest still load
- **Monitoring** for multiple servers: per-server opt-in, refresh intervals from manual to 1 hour, calculated status (Good / Review / Warning / Offline / Unknown)
- Honest freshness: every server shows when it was last checked, and the last known data stays visible when a server goes offline

### Security
A lightweight, read-only audit of the connected server:
- Authentication log analysis (failed logins, invalid users, root logins, sudo activity)
- Listening ports
- SSH daemon configuration
- User accounts (UID 0, login-capable, sudo/wheel groups)
- Persistence (cron, systemd timers, `authorized_keys`)
- Sensitive file permissions
- Package activity (apt, dnf, apk)
- Docker (containers, privileged containers)

Each finding has a detail view with evidence, the command used and a recommended action, and results can be exported as JSON through the Android share sheet.

**This is an audit aid, not antivirus, EDR or a vulnerability scanner.** Findings are labelled PASS, INFO, REVIEW or WARNING and need a human to interpret them. An open port is not automatically a vulnerability, and a changed file is not automatically malware.

## Security and privacy

- **No account, no backend, no analytics.** The app connects directly from your device to your servers.
- **Credentials** (passwords, private keys, passphrases) are stored with `flutter_secure_storage` (Android Keystore-backed), never in SharedPreferences or plain files.
- **Host-key verification is always on.** Unknown hosts show a fingerprint prompt, and a changed host key stops the connection with a clear warning. There is no "ignore" shortcut. Trusted hosts can be reviewed and removed under Settings → Known SSH Hosts.
- Health and security checks are **read-only**. Commands that modify a server need explicit confirmation.
- Passwords, keys and passphrases are never logged.

## Requirements

- Flutter SDK (Dart `>=3.3.0 <4.0.0`)
- Android device or emulator
- A Linux server reachable over SSH (tested with standard OpenSSH servers)

## Build and run

```bash
git clone https://github.com/s1317y/serverDr
cd serverdr

flutter pub get
dart run flutter_launcher_icons   # generates the launcher icons
flutter run
```

Make sure `android/app/src/main/AndroidManifest.xml` includes the network permission, otherwise release builds can't open sockets:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Some plugins require a recent `compileSdk` (36 at the time of writing). If Gradle complains, update `compileSdk` in your Android project, or upgrade Flutter.

To check the project:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Tech stack

| Area | Package |
|---|---|
| SSH and SFTP | [`dartssh2`](https://pub.dev/packages/dartssh2) |
| Terminal emulator | [`xterm`](https://pub.dev/packages/xterm) |
| Secure credential storage | [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) |
| Key file selection and file picking | [`file_picker`](https://pub.dev/packages/file_picker) |
| In-app browser | [`webview_flutter`](https://pub.dev/packages/webview_flutter) |
| Export and sharing | [`share_plus`](https://pub.dev/packages/share_plus) |
| Navigation | [`go_router`](https://pub.dev/packages/go_router) |
| State management | [`provider`](https://pub.dev/packages/provider) |
| Local preferences | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |

Networking sits behind service interfaces (`SshService`, `SftpService`, `HealthService` and others), so screens don't depend on a specific SSH library.

## Known limitations

- **Android only.** iOS and Web are not supported. Browsers can't open raw SSH/SFTP sockets, so a web version would need a different architecture.
- **FTP/FTPS is not implemented.**
- **Light theme is not functional yet.** The Dark/Light/System setting exists, but Light currently renders the same as Dark. Making every custom surface theme-aware is planned work.
- **No true background monitoring.** Scheduled checks only run while the app process is alive. Android may suspend or kill the app, and the UI shows the real last-checked time instead of implying live monitoring. WorkManager-based scheduling is future work.
- **Push notifications and alerting are not implemented.**
- **SFTP downloads and uploads run in memory,** so very large files are not streamed to disk.
- SFTP and the terminal use separate SSH connections to the same server.
- Not yet built: log explorer, recent-file-change diffing, web log analysis, custom security checks, per-container Docker health.

## Roadmap

Planned, but not implemented in this build:

- Full light theme
- Background monitoring and alert notifications
- Log explorer and file-change analysis
- Streamed large-file transfers
- Further platforms

## Contributing

Issues and pull requests are welcome. Please open an issue first to discuss larger changes.

## License

<!-- Add a LICENSE file and state it here, e.g. "MIT — see LICENSE". -->
Not yet specified.

## Author

**Muhammad Sibily P. S.** — Creator / Developer
