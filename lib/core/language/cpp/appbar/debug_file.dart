import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_studio/core/language/cpp/cpp_language.dart';

class DebugFile extends AppbarActionItem {
  bool _isRunning = false;

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    return (path?.endsWith(".cpp") == true ||
            path?.endsWith(".cc") == true ||
            path?.endsWith(".cxx") == true) &&
        !_isRunning;
  }

  @override
  bool get enabled => true;

  @override
  Future<dynamic> execute(EditorContext context) async {
    final language = context.language;

    if (language == null || language is! CPPLanguage) {
      context.showMessage(message: "C++ language not active");
      return;
    }

    final filePath = context.currentFilePath;

    if (filePath == null) {
      context.showMessage(message: "No file selected");
      return;
    }

    final sessionManager = language.sessionManager;

    context.bottomRegistry?.selectItemById(CPPLanguage.outputTerminalId);

    if (sessionManager == null) {
      context.showMessage(message: "Terminal not initialized");
      return;
    }

    final fileName = p.basenameWithoutExtension(filePath);
    final dir = p.dirname(filePath);

    final outputPath = p.join(dir, fileName);

    _isRunning = true;

    try {
      // Compile with debug symbols
      await sessionManager.executeInSession(
        'editor.terminal.output_window',
        'clang++ "$filePath" -g -o "$outputPath"',
      );

      // Run
      await sessionManager.executeInSession(
        'editor.terminal.output_window',
        '"$outputPath"',
      );
    } finally {
      _isRunning = false;
    }
  }

  @override
  Widget? get icon => _isRunning
      ? Image.asset("assets/action_icons/stop.png")
      : Image.asset("assets/action_icons/debug.png");

  @override
  String get id => "editor.cpp.appbar.debug_file";

  @override
  bool isVisible(EditorContext context) => true;

  @override
  String get label => "Compile";

  @override
  String? get subtitle => "Compile C++ file with debug symbols";

  @override
  int get order => 0;

  @override
  bool get visible => true;

  @override
  bool get requiresUIThread => false;

  @override
  Future<void> prepare(EditorContext context) async {
    await super.prepare(context);
  }

  @override
  Future<void> postExecute(EditorContext context, dynamic result) async {}

  @override
  Future<void> dispose() async {}
}
