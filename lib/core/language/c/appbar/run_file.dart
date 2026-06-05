import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_studio/core/language/c/c_language.dart';

class RunFile extends AppbarActionItem {
  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    return (context.currentFilePath?.endsWith(".c") ?? false);
  }

  @override
  Future<void> dispose() async {}

  @override
  bool get enabled => true;

  @override
  Future<dynamic> execute(EditorContext context) async {
    final language = context.language;

    context.bottomRegistry?.selectItemById(CLanguage.outputTerminalId);

    if (language == null) {
      context.showMessage(message: "Language not found");
      return;
    }

    final sessionManager = language.sessionManager;

    if (sessionManager == null) {
      context.showMessage(message: "Terminal not initialized");
      return;
    }

    final filePath = context.currentFilePath;

    if (filePath == null) {
      context.showMessage(message: "No file selected");
      return;
    }

    final fileWithoutExtension = p.join(
      p.dirname(filePath),
      p.basenameWithoutExtension(filePath),
    );

    await sessionManager.executeInSession(
      CLanguage.outputTerminalId,
      'bash "$fileWithoutExtension"',
    );
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/run.png");

  @override
  String get id => "editor.c.appbar.run_file";

  @override
  bool isVisible(EditorContext context) {
    return true;
  }

  @override
  String get label => "Run";

  @override
  int get order => 0;

  @override
  Future<void> postExecute(EditorContext context, dynamic result) async {
    debugPrint("Execution result: $result");
  }

  @override
  Future<void> prepare(EditorContext context) async {
    await super.prepare(context);
  }

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Run your file";

  @override
  bool get visible => true;
}
