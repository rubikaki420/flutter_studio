import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;

class RunFile extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    return path?.endsWith('.ts') == true;
  }

  @override
  Widget? buildActionView(EditorContext context) => null;

  bool _hasTsProject(String dir) {
    return File(p.join(dir, 'tsconfig.json')).existsSync();
  }

  @override
  Future<void> execute(EditorContext context) async {
    final sessionManager = context.language?.sessionManager;

    if (sessionManager == null) {
      context.showMessage(message: "Terminal not initialized");
      return;
    }

    final filePath = context.currentFilePath;

    if (filePath == null) {
      context.showMessage(message: "No file selected");
      return;
    }

    context.bottomRegistry?.selectItemById(outputTerminalId);

    final dir = p.dirname(filePath);

    String command;

    if (_hasTsProject(dir)) {
      command = 'npx ts-node "$filePath"';
    } else {
      command = 'npx ts-node "$filePath"';
    }

    await sessionManager.executeInSession(outputTerminalId, command);
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/run.png");

  @override
  String get id => "editor.ts.appbar.run_file";

  @override
  String get label => "Run";

  @override
  int get order => 0;

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Run TypeScript file";

  @override
  bool get visible => true;

  @override
  Future<void> dispose() async {}
}
