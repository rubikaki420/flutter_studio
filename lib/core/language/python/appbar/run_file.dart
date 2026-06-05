import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;

class RunFile extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    return path?.endsWith('.py') ?? false;
  }

  @override
  Future<void> dispose() async {}

  @override
  bool get enabled => true;

  bool _isPythonProject(String dir) {
    return File(p.join(dir, 'pyproject.toml')).existsSync() ||
        File(p.join(dir, 'requirements.txt')).existsSync() ||
        File(p.join(dir, 'setup.py')).existsSync() ||
        File(p.join(dir, 'main.py')).existsSync();
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

  // ignore: unused_element
  bool _hasVirtualEnv(String projectRoot) {
    return Directory(p.join(projectRoot, '.venv')).existsSync() ||
        Directory(p.join(projectRoot, 'venv')).existsSync();
  }

  String _pythonExecutable(String projectRoot) {
    final venvPython = p.join(projectRoot, '.venv', 'bin', 'python');

    final altVenvPython = p.join(projectRoot, 'venv', 'bin', 'python');

    if (File(venvPython).existsSync()) {
      return '"$venvPython"';
    }

    if (File(altVenvPython).existsSync()) {
      return '"$altVenvPython"';
    }

    return 'python';
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

    context.bottomRegistry?.selectItemById(outputTerminalId);

    final currentDir = p.dirname(filePath);
    final projectRoot = _findProjectRoot(currentDir);

    String command;

    if (projectRoot != null) {
      final pythonExe = _pythonExecutable(projectRoot);

      final relativePath = p.relative(filePath, from: projectRoot);

      command = 'cd "$projectRoot" && $pythonExe "$relativePath"';
    } else {
      command = 'python "$filePath"';
    }

    await sessionManager.executeInSession(outputTerminalId, command);
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/run.png");

  @override
  String get id => "editor.python.appbar.run_file";

  @override
  String get label => "Run";

  @override
  int get order => 0;

  @override
  Future<void> postExecute(EditorContext context, dynamic result) async {
    // debugPrint(
    // "Python execution finished: $result",
    // );
  }

  @override
  Future<void> prepare(EditorContext context) async {
    await super.prepare(context);
  }

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Run Python file/project";

  @override
  bool get visible => true;
}
