import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;

class FormatFile extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    return path?.endsWith('.dart') ?? false;
  }

  @override
  bool get enabled => true;

  @override
  String get id => "editor.dart.appbar.format_file";

  @override
  String get label => "Format";

  @override
  int get order => 1;

  bool _isDartProject(String dir) {
    return File(p.join(dir, 'pubspec.yaml')).existsSync();
  }

  @override
  Future execute(EditorContext context) async {
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

    final dir = p.dirname(filePath);
    final isProject = _isDartProject(dir);

    context.bottomRegistry?.selectItemById(outputTerminalId);

    final command = isProject
        ? 'cd ${context.workspaceDirectory!} && dart format .'
        : 'dart format "$filePath"';

    await sessionManager.executeInSession(outputTerminalId, command);
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/format.png");

  @override
  Future<void> dispose() async {}

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Format Dart file / project";

  @override
  bool get visible => true;
}
