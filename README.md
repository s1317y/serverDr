# ServerKit

Lightweight professional IT support / server administration app (Flutter,
Android-first). This phase moves SSH and SFTP from mock to **real**
networking; FTP/FTPS stays mocked/UI-only per the phase boundary.

## Before you run it — Android manifest

This repo does not ship an `android/` folder (see "Getting it running"
below for why). Once you generate one, **you must add the INTERNET
permission** — without it every SSH/SFTP socket connect will fail
immediately:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET" />
    <application ...>
```

Debug builds usually get this for free from Flutter tooling; **release
builds do not** unless it's explicitly in the manifest. No other special
permission is needed — `file_picker` uses Android's Storage Access
Framework, which needs no manifest entry or runtime permission grant.

## Getting it running

Same as before — this sandbox has no Flutter/Dart SDK, so none of this
has been run through `flutter analyze` / `flutter build` / `flutter run`.
That matters more this time than last: this phase integrates a real
third-party protocol library (`dartssh2`) whose exact method/property
names I confirmed from published docs and its official `xterm` pairing
example, but could not compile-check. Treat your first local build as
the real test — see "Known limitations" below for the specific spots
most likely to need a small fix, and paste me any compiler errors.

1. Generate the platform folders (unchanged from before):
   ```bash
   flutter create --org com.yourcompany --project-name serverkit scratch
   cp -r scratch/android ./android
   rm -rf scratch
   ```
2. Add the INTERNET permission above.
3. `flutter pub get`
4. `flutter run`

## What's real now vs. still mocked

| Area | Status |
|---|---|
| SSH connect/auth (password + private key) | **Real** — `dartssh2` |
| SSH interactive terminal | **Real** — `dartssh2` pty + `xterm` renderer |
| SSH host-key verification (new + changed) | **Real** — persisted via secure storage |
| SFTP connect/list/read/write/rename/delete/mkdir | **Real** — `dartssh2` |
| SFTP download/upload | **Real**, in-memory (not chunked-streamed — fine for config/log-sized files; very large files aren't streamed to disk incrementally yet) |
| Secure credential storage (password/key/passphrase) | **Real** — Android Keystore via `flutter_secure_storage` |
| Saved connection profiles | **Real**, persisted via `shared_preferences` (secrets excluded — those live in secure storage) |
| Test Connection | **Real** — goes through the same `SshService.testConnection` real auth path |
| Transfer Manager UI | **Real progress** for SFTP downloads/uploads triggered from the Files screen; the "2 seed transfers" demo data still self-simulates for UI polish — see `MockTransferManager` |
| Command Palette / dangerous-command confirmation | UI complete, real (no networking involved — inserts into the real command input) |
| FTP/FTPS | Still mocked/UI-only — explicitly out of scope per the phase boundary |
| Web browser tab | Still stub navigation state, no real WebView — out of scope per the phase boundary |
| Quick Connect (ephemeral, no saved profile) | **Not implemented this phase** — only saved-profile connect exists |
| Editor syntax highlighting | Still absent (was already a known Phase 1 gap) |

## Status-bar fix

Root cause: the custom `AppTopBar` was a raw `Container` in a
hand-rolled `PreferredSizeWidget`, so it never got Flutter's built-in
top-inset handling. Fixed by rebuilding it as a real `AppBar` (which
handles the system status-bar inset internally) plus
`SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` and an
`AnnotatedRegion<SystemUiOverlayStyle>` around the app root for icon
contrast. No screen has a manual top-padding number anywhere — this
should hold across phones, tall status bars, and notches without
per-screen tweaks.

## Dependencies added this phase

See `pubspec.yaml` — every dependency has an inline comment explaining
what it's for, why it was chosen over alternatives, and its known
limitations (`dartssh2`, `xterm`, `flutter_secure_storage`, `file_picker`,
`shared_preferences`).

## Architecture changes worth knowing about

- **`SshSession`'s shape changed** from Phase 1's structured
  "entries" list (lines, tables, ...) to a raw byte stream. A real
  interactive shell's output contains ANSI/VT100 escape sequences that
  only a real terminal emulator can correctly interpret — trying to
  model that as discrete "lines" (as the old mock did) cannot represent
  a real shell. `MockSshService` was **removed** rather than rewritten
  to the new shape, since a byte-stream-emitting mock would need to
  synthesize believable ANSI sequences to be useful, which felt like
  scope better spent on the real path. `MockSftpService` was **kept** —
  its interface didn't need to change shape, so it's still available as
  a demo/offline fallback behind the same `SftpService` interface.
- **Host-key verification is a callback the UI supplies**, not something
  the service resolves internally: `SshService.connect`/`SftpService.connect`
  take an `onHostKeyVerification` handler. The Terminal screen, Files
  screen, and connection editor's Test Connection each pass their own
  (all rendering the same `showHostKeyVerificationDialog`). This keeps
  the networking layer decoupled from navigation/`BuildContext`.
- **SSH and SFTP open separate connections** for the same server profile
  — there's no shared/pooled `SSHClient` between the Terminal and Files
  tabs yet. Both go through the same `HostKeyStore`, so trusting a host
  from either screen trusts it for both; they just don't share the
  socket. Worth revisiting if connection setup latency becomes
  noticeable in practice.

## Known limitations / most likely spots to need a fix on first build

I confirmed `dartssh2`'s API from its published docs and its official
paired `xterm` example (`SSHClient`, `onVerifyHostKey`, `client.shell(pty:)`,
`SSHSession.write`/`.resizeTerminal`, `SftpClient.open`/`.readBytes`/
`.writeBytes`/`.listdir`/`.rename`/`.remove`/`.mkdir`), but a few details
were reasonable inferences rather than confirmed against a real compile:

- `SftpStatusCode` enum member names (`noSuchFile`, `permissionDenied`,
  `opUnsupported`) — the underlying SFTP protocol codes are standard, but
  I'm not 100% certain of dartssh2's exact Dart enum naming.
- `SftpFileOpenMode.create | .write | .truncate` — assumed this is a
  bitwise-flags type supporting `|`.
- `SSHPtyConfig(width:, height:)` and `Terminal(maxLines:)` /
  `TerminalView(..., backgroundOpacity:, padding:)` parameter names.
- `SSHKeyPair.fromPem(pem, passphrase)`'s exact handling of a wrong
  passphrase (mapped to `SSHKeyDecryptError` based on the class list
  description, which is somewhat ambiguous).

None of these are architectural risks — if `flutter analyze` flags any
of them, it'll be a one-line property/enum-name fix, not a redesign.
Paste me the errors and I'll fix them directly.

Also unimplemented/simplified vs. the full brief:
- No OpenSSH "randomart" ASCII art on the host-verification dialog (SHA256
  fingerprint text is there; the decorative art box from the Stitch shot
  isn't).
- SFTP download/upload load the whole file into memory rather than
  streaming to disk incrementally — fine for config/log files, a real
  risk for multi-GB transfers.
- "Clear Session Data" in Settings is still a UI-only placeholder.
- No automated tests yet (see the brief's testing section) — next up if
  you want this phase to also cover that before moving on.

## Commands

```bash
flutter pub get       # install dependencies
flutter analyze        # static analysis — run this first after pub get
flutter run            # run on a connected device/emulator
```

No test suite exists yet in this phase (see "Known limitations").

## Testing SSH/SFTP manually

1. Add a connection profile pointing at a real Ubuntu/Debian/Rocky/Alma
   box you control, with either password or private-key auth.
2. Tap **Test Connection** in the editor before saving — this exercises
   the exact same auth path as the real terminal/SFTP screens.
3. First connect to a never-before-seen host: expect the "New SSH Host
   Verification" dialog with a `SHA256:...` fingerprint. Compare it
   against `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` (or
   equivalent) run directly on the server.
4. To test the changed-host-key path: `ssh-keygen -R <host>` locally
   won't affect this app (it has its own store); instead, regenerate the
   server's host key (`ssh-keygen -A` after removing
   `/etc/ssh/ssh_host_*` on a test box) and reconnect — expect the red
   "SSH Host Key Changed" dialog with Disconnect as the safe default.
5. Wrong password / wrong key / wrong passphrase should each surface a
   distinct error via `ErrorStateView` rather than a generic failure.
6. In Files, open a small text file, edit it, Save, then re-open it (or
   check it directly on the server) to confirm the write actually landed
   remotely — this is real now, not the Phase 1 mock buffer.
