import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../settings/services/ui_preferences_controller.dart';
import '../../sftp/models/remote_file.dart';
import '../../sftp/services/sftp_service.dart';

enum _SaveState { saved, modified, saving, failed }

/// Remote file editor — reads and writes the ACTUAL remote file over the
/// authenticated SFTP connection (`SftpService.readFile`/`writeFile`,
/// both real since the SSH/SFTP phase). Handles the full save lifecycle
/// honestly: dirty tracking, a real save-failed state that keeps the
/// user's edits and shows the actual error, an explicit
/// Save/Discard/Cancel prompt before any navigation that would lose
/// unsaved changes, and a distinct permission-denied message rather than
/// a generic failure.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.entry});

  final RemoteFile entry;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _controller = TextEditingController();
  final _editorScrollController = ScrollController();
  final _gutterScrollController = ScrollController();
  final List<String> _history = [];
  int _historyIndex = -1;
  bool _loading = true;
  _SaveState _saveState = _SaveState.saved;
  String? _lastError;
  int _lineCount = 1;
  String _savedContent = '';

  bool get _dirty => _controller.text != _savedContent;

  @override
  void initState() {
    super.initState();
    _editorScrollController.addListener(() {
      if (_gutterScrollController.hasClients) {
        _gutterScrollController.jumpTo(_editorScrollController.offset);
      }
    });
    _load();
  }

  Future<void> _load() async {
    final content = await context.read<SftpService>().readFile(widget.entry.path);
    _controller.text = content;
    _savedContent = content;
    _pushHistory(content);
    setState(() {
      _loading = false;
      _lineCount = '\n'.allMatches(content).length + 1;
    });
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {
      _lineCount = '\n'.allMatches(_controller.text).length + 1;
      if (_saveState != _SaveState.saving) {
        _saveState = _dirty ? _SaveState.modified : _SaveState.saved;
      }
    });
  }

  void _pushHistory(String value) {
    _history
      ..removeRange(_historyIndex + 1, _history.length)
      ..add(value);
    _historyIndex = _history.length - 1;
  }

  void _commitSnapshot() {
    if (_history.isEmpty || _history[_historyIndex] != _controller.text) {
      _pushHistory(_controller.text);
    }
  }

  void _undo() {
    if (_historyIndex <= 0) return;
    _historyIndex--;
    _controller.value = TextEditingValue(text: _history[_historyIndex]);
    setState(() {});
  }

  void _redo() {
    if (_historyIndex >= _history.length - 1) return;
    _historyIndex++;
    _controller.value = TextEditingValue(text: _history[_historyIndex]);
    setState(() {});
  }

  Future<bool> _save() async {
    final content = _controller.text;
    setState(() {
      _saveState = _SaveState.saving;
      _lastError = null;
    });
    try {
      await context.read<SftpService>().writeFile(widget.entry.path, content);
      _commitSnapshot();
      if (!mounted) return true;
      setState(() {
        _savedContent = content;
        _saveState = _SaveState.saved;
      });
      return true;
    } on AppFailure catch (f) {
      // Per the brief: keep the edited content, show the real error, do
      // NOT clear dirty state — the save did not actually happen.
      if (!mounted) return false;
      setState(() {
        _saveState = _SaveState.failed;
        _lastError = f.kind == AppFailureKind.permissionDenied
            ? 'Permission denied — this file may be read-only for the connected user.'
            : f.title;
      });
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _saveState = _SaveState.failed;
        _lastError = 'Failed to save file';
      });
      return false;
    }
  }

  /// Shown before any navigation that would discard unsaved changes.
  /// Returns true if it's safe to proceed (saved, discarded, or nothing
  /// to lose); false if the user cancelled.
  Future<bool> _confirmLeaveIfDirty() async {
    if (!_dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save changes?'),
        content: Text('${widget.entry.name} has unsaved changes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save')),
        ],
      ),
    );
    switch (choice) {
      case 'save':
        return _save();
      case 'discard':
        return true;
      default:
        return false;
    }
  }

  Future<void> _find() async {
    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Find'),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Search text')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Find')),
          ],
        );
      },
    );
    if (query == null || query.isEmpty) return;
    final index = _controller.text.indexOf(query);
    if (index == -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$query" not found')));
      }
      return;
    }
    _controller.selection = TextSelection(baseOffset: index, extentOffset: index + query.length);
  }

  Future<void> _goToLine() async {
    final input = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Go to line'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Line number'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Go')),
          ],
        );
      },
    );
    final line = int.tryParse(input ?? '');
    if (line == null) return;
    final lines = _controller.text.split('\n');
    final target = (line - 1).clamp(0, lines.length - 1);
    final offset = lines.take(target).fold<int>(0, (acc, l) => acc + l.length + 1);
    _controller.selection = TextSelection.collapsed(offset: offset);
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    _gutterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<UiPreferencesController>().editorFontSize;
    final lineHeight = fontSize * (20 / 12);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmLeaveIfDirty() && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.entry.name, style: const TextStyle(fontFamily: 'Geist', fontSize: 15)),
              Text(
                widget.entry.path,
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            IconButton(onPressed: _find, icon: const Icon(Icons.search), tooltip: 'Find'),
            IconButton(onPressed: _goToLine, icon: const Icon(Icons.numbers), tooltip: 'Go to line'),
            IconButton(onPressed: _historyIndex > 0 ? _undo : null, icon: const Icon(Icons.undo), tooltip: 'Undo'),
            IconButton(
                onPressed: _historyIndex < _history.length - 1 ? _redo : null,
                icon: const Icon(Icons.redo),
                tooltip: 'Redo'),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _dirty && _saveState != _SaveState.saving ? _save : null,
                icon: _saveState == _SaveState.saving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save, size: 16),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _saveStateBanner(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 40,
                          color: AppColors.surfaceContainerLowest,
                          child: ListView.builder(
                            controller: _gutterScrollController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _lineCount,
                            itemBuilder: (context, index) => SizedBox(
                              height: lineHeight,
                              child: Text(
                                '${index + 1}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: fontSize,
                                  color: AppColors.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: AppColors.outlineVariant),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _editorScrollController,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextField(
                                controller: _controller,
                                maxLines: null,
                                style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: fontSize, height: 20 / 12, color: AppColors.onSurface),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                onEditingComplete: _commitSnapshot,
                                onTapOutside: (_) => _commitSnapshot(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _saveStateBanner() {
    final (label, color, icon) = switch (_saveState) {
      _SaveState.saved => ('SAVED', AppColors.secondary, Icons.check_circle_outline),
      _SaveState.modified => ('UNSAVED CHANGES', AppColors.tertiary, Icons.circle),
      _SaveState.saving => ('SAVING...', AppColors.primary, Icons.sync),
      _SaveState.failed => ('SAVE FAILED', AppColors.error, Icons.error_outline),
    };
    return Container(
      width: double.infinity,
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          if (_saveState == _SaveState.failed && _lastError != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(_lastError!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.error)),
            ),
            TextButton(onPressed: _save, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
