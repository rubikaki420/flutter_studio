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

    return _findProjectRoot(p.dirname(path)) != null;
  }

  bool _isPythonProject(String dir) {
    return File(p.join(dir, 'requirements.txt')).existsSync() ||
        File(p.join(dir, 'pyproject.toml')).existsSync() ||
        File(p.join(dir, 'setup.py')).existsSync();
  }

  String? _findProjectRoot(String startDir) {
    Directory current = Directory(startDir);

    while (true) {
      if (_isPythonProject(current.path)) {
        return current.path;
      }

      final parent = current.parent;

      if (parent.path == current.path) {
        return null;
      }

      current = parent;
    }
  }

  @override
  Future<dynamic> execute(EditorContext context) async {
    final language = context.language;

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

    final projectRoot = _findProjectRoot(p.dirname(filePath));

    if (projectRoot == null) {
      context.showMessage(message: "Python project not found");
      return;
    }

    context.bottomRegistry?.selectItemById(outputTerminalId);

    String command;

    if (File(p.join(projectRoot, 'requirements.txt')).existsSync()) {
      command = 'cd "$projectRoot" && pip install -r requirements.txt';
    } else if (File(p.join(projectRoot, 'pyproject.toml')).existsSync()) {
      command = 'cd "$projectRoot" && pip install -e .';
    } else if (File(p.join(projectRoot, 'setup.py')).existsSync()) {
      command = 'cd "$projectRoot" && pip install -e .';
    } else {
      context.showMessage(message: "Nothing to sync");
      return;
    }

    await sessionManager.executeInSession(outputTerminalId, command);
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/sync.png");

  @override
  String get id => "editor.python.appbar.sync_project";

  @override
  String get label => "Sync";

  @override
  int get order => 2;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> postExecute(EditorContext context, dynamic result) async {}

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Install project dependencies";

  @override
  bool get enabled => true;

  @override
  bool get visible => true;
}
