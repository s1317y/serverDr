import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/server_connection_sheet.dart';
import '../../connections/models/connection_profile.dart';
import '../../connections/models/server_connection_state.dart';
import '../../connections/services/connection_repository.dart';
import '../../connections/services/server_connection_manager.dart';
import '../../settings/services/ui_preferences_controller.dart';
import '../models/ssh_session_state.dart';
import '../services/ssh_service.dart';
import '../widgets/command_input_bar.dart';
import '../widgets/command_palette_sheet.dart';
import '../widgets/host_key_verification_dialog.dart';
import '../widgets/terminal_key_bar.dart';

/// Real interactive SSH terminal.
///
/// IMPORTANT: this screen does NOT auto-connect just because it's opened
/// or the active server changes — a saved server is not a connected
/// server (see `ServerConnectionManager`'s doc). It shows a "Not
/// Connected" prompt with an explicit Connect action, and reattaches to
/// an already-live session (opened from here, from Saved Connections, or
/// left running from a previous visit) without reconnecting.
///
/// ANSI/VT100 handling (cursor movement, color, screen clears, full-screen
/// programs like `vim`/`htop`) is delegated entirely to the `xterm`
/// package's [Terminal] + [TerminalView].
class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _inputController = TextEditingController();
  final _commandHistory = <String>[];
  int _historyCursor = -1;

  final Terminal _terminal = Terminal(maxLines: 10000);
  SshSession? _session;
  AppFailure? _failure;
  String? _attachedToId;
  String? _lastSeenActiveId;

  @override
  void initState() {
    super.initState();
    _terminal.onOutput = (data) {
      _session?.sendRaw(utf8.encode(data));
    };
    _terminal.onResize = (w, h, pw, ph) {
      _session?.resize(w, h, pw, ph);
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = context.watch<ConnectionRepository>().activeConnection;
    if (active == null) {
      _lastSeenActiveId = null;
      return;
    }
    // IMPORTANT: this must only react when the ACTIVE SERVER itself
    // changes — not on every rebuild. `build()` also watches
    // ServerConnectionManager, so every state transition during a
    // connect (connecting -> authenticating -> connected) triggers
    // didChangeDependencies too. The old check here was `active.id !=
    // _attachedToId`, which stays true for the whole connect operation
    // and was resetting `_session` back to null mid-connect — sometimes
    // right after a successful attach — making the first Connect tap
    // appear to silently fail even though the SSH session had actually
    // come up (a second attempt after leaving/returning would then just
    // reattach to that already-live session instantly, matching the
    // reported bug exactly). Comparing against `_lastSeenActiveId`
    // instead makes this run only once per actual server switch.
    if (active.id == _lastSeenActiveId) return;
    _lastSeenActiveId = active.id;

    if (active.id != _attachedToId) {
      final existing = context.read<SshService>().sessionFor(active.id);
      if (existing != null && existing.state == SshSessionState.connected) {
        _attachSession(active.id, existing);
      } else {
        _attachedToId = null;
        setState(() => _session = null);
      }
    }
  }

  Future<void> _connect(ConnectionProfile profile) async {
    setState(() {
      _failure = null;
    });
    try {
      final manager = context.read<ServerConnectionManager>();
      await manager.connect(profile, onHostKeyVerification: (r) => showHostKeyVerificationDialog(context, r));
      final session = context.read<SshService>().sessionFor(profile.id);
      if (session != null) _attachSession(profile.id, session);
    } on AppFailure catch (f) {
      if (!mounted) return;
      setState(() => _failure = f);
    }
  }

  void _attachSession(String profileId, SshSession session) {
    _attachedToId = profileId;
    _terminal.buffer.clear();
    setState(() => _session = session);
    session.stateStream.listen((_) => mounted ? setState(() {}) : null);
    session.output.transform(const Utf8Decoder(allowMalformed: true)).listen(_terminal.write);
  }

  Future<void> _submitLine() async {
    final text = _inputController.text;
    if (text.trim().isEmpty || _session == null) return;
    _commandHistory.add(text);
    _historyCursor = _commandHistory.length;
    _inputController.clear();
    await _session!.sendLine(text);
  }

  void _historyPrev() {
    if (_commandHistory.isEmpty) return;
    _historyCursor = (_historyCursor - 1).clamp(0, _commandHistory.length - 1);
    _inputController.text = _commandHistory[_historyCursor];
    _inputController.selection = TextSelection.collapsed(offset: _inputController.text.length);
  }

  Future<void> _openPalette() async {
    final resolved = await showCommandPaletteSheet(context);
    if (resolved == null) return;
    setState(() {
      _inputController.text = resolved;
      _inputController.selection = TextSelection.collapsed(offset: resolved.length);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connections = context.watch<ConnectionRepository>();
    final active = connections.activeConnection;
    context.watch<ServerConnectionManager>(); // rebuild on state changes

    return Scaffold(
      appBar: AppTopBar(
        sectionLabel: 'Terminal',
        activeConnection: active,
        onTapConnectionPill: () => showServerConnectionSheet(context, active),
        onTapConnections: () => context.push('/connections'),
        onTapProfile: () => context.push('/settings'),
        onTapTransfers: () => context.push('/transfers'),
      ),
      body: _buildBody(active),
    );
  }

  Widget _buildBody(ConnectionProfile? active) {
    if (active == null) {
      return const EmptyStateView(
        icon: Icons.dns_outlined,
        title: 'No server selected',
        subtitle: 'Pick a saved connection to open a terminal session.',
      );
    }
    if (_failure != null) {
      return ErrorStateView(
        failure: _failure!,
        actions: [
          RecoveryAction(label: 'Retry', isPrimary: true, onPressed: () => _connect(active)),
          RecoveryAction(label: 'Edit Connection', onPressed: () => context.push('/connections/${active.id}/edit')),
        ],
      );
    }

    final session = _session;
    if (session == null || session.state != SshSessionState.connected) {
      final manager = context.watch<ServerConnectionManager>();
      final connecting = manager.stateFor(active.id).isTransient;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.terminal, size: 40, color: AppColors.outline),
              const SizedBox(height: 12),
              Text(
                connecting ? 'Connecting...' : 'Not connected',
                style: const TextStyle(fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${active.username}@${active.host}:${active.port}',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (connecting)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: () => _connect(active),
                  icon: const Icon(Icons.power_settings_new, size: 18),
                  label: const Text('Connect'),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _StatusStrip(profile: active, state: session.state),
        Expanded(
          child: ColoredBox(
            color: AppColors.surfaceContainerLowest,
            child: TerminalView(
              _terminal,
              autofocus: true,
              backgroundOpacity: 0,
              padding: const EdgeInsets.all(8),
              textStyle: TerminalStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: context.watch<UiPreferencesController>().terminalFontSize,
              ),
              // Android soft keyboards frequently don't send Backspace as
              // a raw hardware key event (especially Gboard/Samsung
              // Keyboard predictive-text modes) — they signal deletion
              // through the IME's text-editing state instead. Without
              // this, typing works but Backspace silently does nothing,
              // which is exactly the reported bug. This makes TerminalView
              // additionally watch the IME composing/editing state for
              // deletions rather than relying solely on raw key events.
              deleteDetection: true,
            ),
          ),
        ),
        TerminalKeyBar(
          onSendRaw: (bytes) => session.sendRaw(bytes),
          onOpenPalette: _openPalette,
        ),
        CommandInputBar(
          controller: _inputController,
          onSubmit: _submitLine,
          onHistoryPrev: _historyPrev,
          enabled: session.state == SshSessionState.connected,
        ),
      ],
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.profile, required this.state});

  final ConnectionProfile profile;
  final SshSessionState state;

  Color get _color => switch (state) {
        SshSessionState.connected => AppColors.secondary,
        SshSessionState.connecting ||
        SshSessionState.authenticating ||
        SshSessionState.hostVerificationRequired =>
          AppColors.tertiary,
        SshSessionState.authenticationFailed ||
        SshSessionState.connectionFailed ||
        SshSessionState.hostKeyChanged =>
          AppColors.error,
        _ => AppColors.outline,
      };

  String get _label => switch (state) {
        SshSessionState.idle => 'IDLE',
        SshSessionState.connecting => 'CONNECTING',
        SshSessionState.hostVerificationRequired => 'VERIFYING HOST',
        SshSessionState.authenticating => 'AUTHENTICATING',
        SshSessionState.connected => 'CONNECTED',
        SshSessionState.disconnecting => 'DISCONNECTING',
        SshSessionState.disconnected => 'DISCONNECTED',
        SshSessionState.authenticationFailed => 'AUTH FAILED',
        SshSessionState.connectionFailed => 'CONNECTION FAILED',
        SshSessionState.hostKeyChanged => 'HOST KEY CHANGED',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${profile.username}@${profile.name} (${profile.host}:${profile.port})',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurface),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
            child: Text(
              _label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
