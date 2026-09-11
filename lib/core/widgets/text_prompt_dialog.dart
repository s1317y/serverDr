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
  controller.dispose();
  if (result == null || result.isEmpty) return null;
  return result;
}
