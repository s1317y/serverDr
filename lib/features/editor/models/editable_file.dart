import 'package:flutter/foundation.dart';

/// The file currently open in the editor. Deliberately minimal for
/// Phase 1 — syntax highlighting/undo-redo history live in the screen's
/// controller, not the model.
@immutable
class EditableFile {
  const EditableFile({required this.path, required this.name, required this.content});

  final String path;
  final String name;
  final String content;
}
