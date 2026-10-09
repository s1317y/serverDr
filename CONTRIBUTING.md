# Contributing to ServerDr

Thanks for your interest in ServerDr. Issues and pull requests are welcome.

## Before you start

- For anything beyond a small fix, **open an issue first** so we can agree on the approach.
- ServerDr connects to people's real servers. Changes that touch SSH, SFTP, host-key verification, credential storage or command execution get extra scrutiny.

## Ground rules

These are non-negotiable for security-sensitive code:

- **Never** disable host-key verification or auto-trust a changed host key.
- **Never** log, print or persist passwords, private keys or passphrases outside secure storage.
- Health and security checks must stay **read-only**. Anything that modifies a server needs explicit user confirmation.
- Don't label findings as "attack", "malware" or "vulnerable" unless the evidence supports it. Use PASS / INFO / REVIEW / WARNING.
- Don't add telemetry, analytics or a required backend.

## Development setup

```bash
git clone <your-repo-url>
cd serverdr
flutter pub get
dart run flutter_launcher_icons
flutter run
```

Before opening a PR:

```bash
flutter analyze
flutter test
```

## Code style

- Follow `flutter_lints` (see `analysis_options.yaml`).
- Keep networking behind the existing service interfaces (`SshService`, `SftpService`, `HealthService`, and so on). Widgets must not talk to `dartssh2` directly.
- Prefer small, focused pull requests over large rewrites.
- Don't rename SharedPreferences keys (they use the `serverkit.*` prefix on purpose). Changing them would wipe existing users' saved data. If a migration is ever needed, add an explicit one.

## Pull requests

- Describe what changed and why.
- Note how you tested it (device, Android version, server OS).
- Update `CHANGELOG.md` for user-visible changes.

## Reporting security issues

Please **don't** open a public issue for vulnerabilities. See [SECURITY.md](SECURITY.md).