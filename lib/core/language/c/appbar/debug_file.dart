import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_studio/core/language/c/c_language.dart';

class DebugFile extends AppbarActionItem {
  bool _isRunning = false;

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    return (context.currentFilePath?.endsWith(".c") ?? false) && !_isRunning;
  }

  @override
  bool get enabled => true;
  //(context.currentFilePath?.endsWith(".c") ?? false); //&& !_isRunning;

  @override
  Future<dynamic> execute(EditorContext context) async {
    final language = context.language;

    if (language == null || language is! CLanguage) {
      context.showMessage(message: "C language not active");
      return;
    }

    context.bottomRegistry?.selectItemById(CLanguage.outputTerminalId);

    final filePath = context.currentFilePath;

    if (filePath == null) {
      context.showMessage(message: "No file selected");
      return;
    }

    final sessionManager = language.sessionManager;

    if (sessionManager == null) {
      context.showMessage(message: "Terminal not initialized");
      return;
    }

    final fileName = p.basenameWithoutExtension(filePath);
    final dir = p.dirname(filePath);

    final outputPath = p.join(dir, fileName);

    _isRunning = true;

    // UI update (icon change)
    // ignore: use_build_context_synchronously

    try {
      // Compile
      await sessionManager.executeInSession(
        CLanguage.outputTerminalId,
        'gcc "$filePath" -g -o "$outputPath"',
      );

      // Run
      await sessionManager.executeInSession(
        CLanguage.outputTerminalId,
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
  String get id => "editor.c.appbar.debug_file";

  @override
  bool isVisible(EditorContext context) => true;

  @override
  String get label => "Compile";

  @override
  int get order => 0;

  @override
  String? get subtitle => "Compile C file only";

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
