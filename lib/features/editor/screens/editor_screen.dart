import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../sftp/models/remote_file.dart';
import '../../sftp/services/sftp_service.dart';

/// Remote file editor.
///
/// PHASE 1 SCOPE: operates on content loaded once via [SftpService.readFile]
/// and "saves" only to [SftpService.writeFile], which is explicitly a
/// mock, in-memory write (see that interface's doc). This screen never
/// claims the remote file was actually updated — the save banner says so
/// outright, and there is no "uploaded" or "synced" language anywhere
/// here. Syntax highlighting is deferred to a later phase; undo/redo here
/// is a simple in-memory snapshot stack, not a real text-editing engine.
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
  bool _dirty = false;
  bool _saving = false;
  int _lineCount = 1;

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
    _pushHistory(content);
    setState(() {
      _loading = false;
      _lineCount = '\n'.allMatches(content).length + 1;
    });
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {
      _dirty = true;
      _lineCount = '\n'.allMatches(_controller.text).length + 1;
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

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<SftpService>().writeFile(widget.entry.path, _controller.text);
    _commitSnapshot();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to local mock buffer — not uploaded to the remote server (Phase 6 adds real save).'),
        duration: Duration(seconds: 4),
      ),
    );
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
    return Scaffold(
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
              onPressed: _dirty && !_saving ? _save : null,
              icon: _saving
                  ? const SizedBox(
                      width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
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
                Container(
                  width: double.infinity,
                  color: AppColors.tertiaryContainer.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: const Text(
                    'Mock mode: edits save to a local buffer only, not the real server.',
                    style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.tertiary),
                  ),
                ),
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
                            height: 20,
                            child: Text(
                              '${index + 1}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
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
                              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, height: 20 / 12, color: AppColors.onSurface),
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
    );
  }
}
