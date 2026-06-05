import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;

class SyncProject extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    if (path == null) return false;

    final dir = p.dirname(path);

    return File(p.join(dir, 'package.json')).existsSync();
  }

  @override
  Widget? buildActionView(EditorContext context) => null;

  bool _isNpmProject(String dir) {
    return File(p.join(dir, 'package.json')).existsSync();
  }

  String _findRoot(String startDir) {
    Directory current = Directory(startDir);

    while (true) {
      if (_isNpmProject(current.path)) {
        return current.path;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        return current.path;
      }

      current = parent;
    }
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

    final root = _findRoot(p.dirname(filePath));

    context.bottomRegistry?.selectItemById(outputTerminalId);

    final command = 'cd "$root" && npm install';

    await sessionManager.executeInSession(outputTerminalId, command);
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/sync.png");

  @override
  String get id => "editor.js.appbar.sync_project";

  @override
  String get label => "Sync";

  @override
  int get order => 2;

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "npm install dependencies";

  @override
  bool get visible => true;

  @override
  Future<void> dispose() async {}
}
