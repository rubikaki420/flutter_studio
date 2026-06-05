import 'package:flutter/material.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'appbar_action_item.dart';

class UndoAction extends AppbarActionItem {
  @override
  String get id => 'editor.action.undo';

  @override
  String get label => 'Undo';

  @override
  Widget? get icon => const Icon(Icons.undo, size: 18);

  @override
  bool canExecute(EditorContext context) {
    return context.activeUndoRedoController?.canUndo ?? false;
  }

  @override
  Future<void> execute(EditorContext context) async {
    context.activeUndoRedoController?.undo();
  }

  @override
  int get order => -100;
}

class RedoAction extends AppbarActionItem {
  @override
  String get id => 'editor.action.redo';

  @override
  String get label => 'Redo';

  @override
  Widget? get icon => const Icon(Icons.redo, size: 18);

  @override
  bool canExecute(EditorContext context) {
    return context.activeUndoRedoController?.canRedo ?? false;
  }

  @override
  Future<void> execute(EditorContext context) async {
    context.activeUndoRedoController?.redo();
  }

  @override
  int get order => -99;
}

class SaveAction extends AppbarActionItem {
  @override
  String get id => 'editor.action.save';

  @override
  String get label => 'Save';

  @override
  Widget? get icon => const Icon(Icons.save, size: 18);

  @override
  bool canExecute(EditorContext context) {
    return context.currentFilePath != null &&
        context.activeCodeForgeController != null;
  }

  @override
  Future<void> execute(EditorContext context) async {
    context.activeCodeForgeController?.saveFile();
  }

  @override
  Future<void> postExecute(EditorContext context, result) async {
    context.showMessage(
      message: "Saved ${context.currentFilePath?.split('/').last}",
    );
  }

  @override
  int get order => -98;
}
