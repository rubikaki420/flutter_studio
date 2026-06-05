import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;

class SyncProject extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    if (path == null) return false;

    final dir = p.dirname(path);
    return File(p.join(dir, 'pubspec.yaml')).existsSync();
  }

  @override
  bool get enabled => true;

  @override
  String get id => "editor.dart.appbar.sync_project";

  @override
  String get label => "Sync";

  @override
  int get order => 2;

  @override
  Future execute(EditorContext context) async {
    final sessionManager = context.language?.sessionManager;

    if (sessionManager == null) {
      context.showMessage(message: "Terminal not initialized");
      return;
    }

    context.bottomRegistry?.selectItemById(outputTerminalId);

    await sessionManager.executeInSession(
      outputTerminalId,
      'cd ${context.workspaceDirectory!} && dart pub get',
    );
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/sync.png");

  @override
  Future<void> dispose() async {}

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Run dart pub get";

  @override
  bool get visible => true;
}
