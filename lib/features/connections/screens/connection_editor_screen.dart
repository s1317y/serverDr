import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/storage/secure_credential_store.dart';
import '../../ssh/models/host_key_verification.dart';
import '../../ssh/services/ssh_service.dart';
import '../../ssh/widgets/host_key_verification_dialog.dart';
import '../models/connection_profile.dart';
import '../services/connection_repository.dart';

enum _TestState { idle, testing, success, failure }

/// Add/edit form for a [ConnectionProfile].
///
/// Secrets typed here go straight to [SecureCredentialStore] on Save —
/// never through `ConnectionRepository`, never logged, never held longer
/// than needed in this form's own state. A private key is only ever read
/// from the file the user picks via the Android document picker
/// ([FilePicker]) and its *content* (not the picked path) is what gets
/// persisted — see [ConnectionProfile.privateKeyFileName]'s doc.
class ConnectionEditorScreen extends StatefulWidget {
  const ConnectionEditorScreen({super.key, this.connectionId});

  /// Null when creating a new connection.
  final String? connectionId;

  @override
  State<ConnectionEditorScreen> createState() => _ConnectionEditorScreenState();
}

class _ConnectionEditorScreenState extends State<ConnectionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _websiteController;
  late final TextEditingController _passwordController;
  late final TextEditingController _passphraseController;
  ConnectionProtocol _protocol = ConnectionProtocol.ssh;
  AuthMethod _authMethod = AuthMethod.password;
  ConnectionProfile? _existing;

  String? _pickedKeyContent;
  String? _pickedKeyFileName;

  _TestState _testState = _TestState.idle;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    final repo = context.read<ConnectionRepository>();
    _existing = null;
    if (widget.connectionId != null) {
      for (final c in repo.connections) {
        if (c.id == widget.connectionId) {
          _existing = c;
          break;
        }
      }
    }

    _nameController = TextEditingController(text: _existing?.name ?? '');
    _hostController = TextEditingController(text: _existing?.host ?? '');
    _portController = TextEditingController(text: (_existing?.port ?? 22).toString());
    _usernameController = TextEditingController(text: _existing?.username ?? '');
    _websiteController = TextEditingController(text: _existing?.websiteUrl ?? '');
    _passwordController = TextEditingController();
    _passphraseController = TextEditingController();
    _protocol = _existing?.protocol ?? ConnectionProtocol.ssh;
    _authMethod = _existing?.authMethod ?? AuthMethod.password;
    _pickedKeyFileName = _existing?.privateKeyFileName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _websiteController.dispose();
    _passwordController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _pickPrivateKey() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedKeyContent = utf8.decode(bytes, allowMalformed: true);
      _pickedKeyFileName = file.name;
      _testState = _TestState.idle;
    });
  }

  ConnectionProfile _buildDraftProfile() {
    return ConnectionProfile(
      id: _existing?.id ?? 'srv-${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim().isEmpty ? _hostController.text.trim() : _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ?? _protocol.defaultPort,
      username: _usernameController.text.trim(),
      protocol: _protocol,
      authMethod: _authMethod,
      websiteUrl: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      hasStoredPassword: _authMethod == AuthMethod.password &&
          (_passwordController.text.isNotEmpty || (_existing?.hasStoredPassword ?? false)),
      hasStoredPrivateKey: _authMethod == AuthMethod.privateKey &&
          (_pickedKeyContent != null || (_existing?.hasStoredPrivateKey ?? false)),
      privateKeyFileName: _authMethod == AuthMethod.privateKey ? _pickedKeyFileName : null,
      lastConnectedAt: _existing?.lastConnectedAt,
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_authMethod == AuthMethod.privateKey && _pickedKeyContent == null && !(_existing?.hasStoredPrivateKey ?? false)) {
      setState(() {
        _testState = _TestState.failure;
        _testMessage = 'Select a private key file first.';
      });
      return;
    }

    setState(() {
      _testState = _TestState.testing;
      _testMessage = null;
    });

    final profile = _buildDraftProfile();
    final sshService = context.read<SshService>();
    final credentialStore = context.read<SecureCredentialStore>();

    try {
      String? privateKeyOverride;
      String? passphraseOverride;
      if (_authMethod == AuthMethod.privateKey) {
        privateKeyOverride = _pickedKeyContent ?? await credentialStore.readPrivateKey(profile.id);
        passphraseOverride = _passphraseController.text.isNotEmpty
            ? _passphraseController.text
            : await credentialStore.readPassphrase(profile.id);
      }
      await sshService.testConnection(
        profile,
        onHostKeyVerification: (request) => showHostKeyVerificationDialog(context, request),
        passwordOverride: _authMethod == AuthMethod.password && _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        privateKeyOverride: privateKeyOverride,
        passphraseOverride: passphraseOverride,
      );
      if (!mounted) return;
      setState(() {
        _testState = _TestState.success;
        _testMessage = 'Connection successful';
      });
    } on AppFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _testState = _TestState.failure;
        _testMessage = f.title;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _testState = _TestState.failure;
        _testMessage = 'Something went wrong';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<ConnectionRepository>();
    final credentialStore = context.read<SecureCredentialStore>();
    final profile = _buildDraftProfile();

    if (_authMethod == AuthMethod.password && _passwordController.text.isNotEmpty) {
      await credentialStore.savePassword(profile.id, _passwordController.text);
    }
    if (_authMethod == AuthMethod.privateKey && _pickedKeyContent != null) {
      await credentialStore.savePrivateKey(
        profile.id,
        privateKey: _pickedKeyContent!,
        passphrase: _passphraseController.text.isEmpty ? null : _passphraseController.text,
      );
    }

    if (_existing == null) {
      await repo.add(profile);
    } else {
      await repo.update(profile);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New Connection' : 'Edit Connection'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Connection Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'Host'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<ConnectionProtocol>(
                    initialValue: _protocol,
                    decoration: const InputDecoration(labelText: 'Protocol'),
                    items: ConnectionProtocol.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                        .toList(),
                    onChanged: (p) => setState(() {
                      _protocol = p!;
                      _portController.text = p.defaultPort.toString();
                      _testState = _TestState.idle;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(labelText: 'Port'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (!_protocol.isEncrypted) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_open, size: 14, color: AppColors.error),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Plain FTP is unencrypted — you'll see a warning every time you connect.",
                        style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const Text('Authentication', style: TextStyle(fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<AuthMethod>(
              segments: AuthMethod.values.map((m) => ButtonSegment(value: m, label: Text(m.label))).toList(),
              selected: {_authMethod},
              onSelectionChanged: (s) => setState(() {
                _authMethod = s.first;
                _testState = _TestState.idle;
              }),
            ),
            const SizedBox(height: 12),

            // Only the fields relevant to the selected auth method are
            // shown — per the brief, never both password and key fields
            // at once.
            if (_authMethod == AuthMethod.password)
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: (_existing?.hasStoredPassword ?? false)
                      ? 'A password is already stored — leave blank to keep it'
                      : 'Stored in Android Keystore-backed secure storage on Save',
                  helperMaxLines: 2,
                ),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: _pickPrivateKey,
                icon: const Icon(Icons.file_open_outlined, size: 18),
                label: Text(_pickedKeyFileName == null ? 'Select Key File' : 'Change Key File'),
              ),
              if (_pickedKeyFileName != null) ...[
                const SizedBox(height: 6),
                Text('Selected: $_pickedKeyFileName',
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.secondary)),
              ] else if (_existing?.hasStoredPrivateKey ?? false) ...[
                const SizedBox(height: 6),
                const Text('A private key is already stored for this profile.',
                    style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _passphraseController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Passphrase (optional)'),
              ),
            ],

            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website URL (optional, for the Web tab)'),
            ),

            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _testState == _TestState.testing ? null : _testConnection,
              icon: _testState == _TestState.testing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering, size: 18),
              label: const Text('Test Connection'),
            ),
            if (_testMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _testState == _TestState.success ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: _testState == _TestState.success ? AppColors.secondary : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _testMessage!,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: _testState == _TestState.success ? AppColors.secondary : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
