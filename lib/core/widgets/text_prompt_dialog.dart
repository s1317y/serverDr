import 'package:flutter/material.dart';

/// Small reusable "enter a name" dialog — used for New Folder, New File,
/// and Rename.
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String confirmLabel = 'Create',
}) async {
  final controller = TextEditingController(text: initialValue);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(fontFamily: 'JetBrains Mono'),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  // Defer disposal to the next frame rather than disposing immediately.
  // showDialog's Future resolves as soon as Navigator.pop() is CALLED —
  // not when the dialog's exit animation finishes — so the TextField
  // above can still be attached to `controller` during that trailing
  // animation frame. Disposing synchronously here was racing that
  // teardown and triggering a framework element-lifecycle assertion
  // ('_dependents.isEmpty') on New Folder / New File / Rename, the only
  // three places that use this dialog.
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  if (result == null || result.isEmpty) return null;
  return result;
}
