import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/server_connection_sheet.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../connections/models/connection_profile.dart';
import '../../connections/services/connection_repository.dart';
import '../models/ssh_session_state.dart';
import '../services/ssh_service.dart';
import '../widgets/command_input_bar.dart';
import '../widgets/command_palette_sheet.dart';
import '../widgets/host_key_verification_dialog.dart';
import '../widgets/terminal_key_bar.dart';

/// Real interactive SSH terminal.
///
/// ANSI/VT100 handling (cursor movement, color, screen clears, full-screen
/// programs like `vim`/`htop`) is delegated entirely to the `xterm`
/// package's [Terminal] + [TerminalView] — this screen's job is just
/// plumbing: pipe [SshSession.output] bytes into the terminal, and pipe
/// the terminal's own input (typed directly into it, OR injected via the
/// key bar / EXEC bar for mobile-friendly control keys) back out to the
/// session.
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
  String? _activeForConnectionId;

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
    if (active != null && active.id != _activeForConnectionId) {
      _activeForConnectionId = active.id;
      _openSession(active);
    }
  }

  Future<void> _openSession(ConnectionProfile profile) async {
    setState(() {
      _failure = null;
      _session = null;
    });
    _terminal.buffer.clear();
    try {
      final sshService = context.read<SshService>();
      final session = await sshService.connect(
        profile,
        onHostKeyVerification: (request) => showHostKeyVerificationDialog(context, request),
      );
      if (!mounted) return;
      setState(() => _session = session);
      session.stateStream.listen((_) => mounted ? setState(() {}) : null);
      session.output.transform(const Utf8Decoder(allowMalformed: true)).listen(_terminal.write);
    } on AppFailure catch (f) {
      if (!mounted) return;
      setState(() => _failure = f);
    }
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
    final picked = await showCommandPaletteSheet(context);
    if (picked == null) return;
    setState(() {
      _inputController.text = picked.command;
      _inputController.selection = TextSelection.collapsed(offset: picked.command.length);
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
          RecoveryAction(label: 'Retry', isPrimary: true, onPressed: () => _openSession(active)),
          RecoveryAction(label: 'Edit Connection', onPressed: () => context.push('/connections/${active.id}/edit')),
        ],
      );
    }
    final session = _session;
    if (session == null) {
      return const LoadingStateView(label: 'Connecting...');
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
