import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;
//import 'package:flutter_studio/core/language/dart/dart_language.dart';

class RunFile extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    return path?.endsWith('.dart') ?? false;
  }

  @override
  Future<void> dispose() async {}

  @override
  bool get enabled => true;

  bool _isDartProject(String dir) {
    return File(p.join(dir, 'pubspec.yaml')).existsSync();
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

    final dir = p.dirname(filePath);
    final isProject = _isDartProject(dir);

    // focus output tab
    context.bottomRegistry?.selectItemById(outputTerminalId);

    String command;

    if (isProject) {
      // Dart project run
      command = 'dart run';
    } else {
      // single file run
      command = 'dart "$filePath"';
    }

    await sessionManager.executeInSession(outputTerminalId, command);
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/run.png");

  @override
  String get id => "editor.dart.appbar.run_file";

  @override
  String get label => "Run";

  @override
  int get order => 0;

  @override
  Future<void> postExecute(EditorContext context, dynamic result) async {
    debugPrint("Dart execution finished: $result");
  }

  @override
  Future<void> prepare(EditorContext context) async {
    await super.prepare(context);
  }

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Run Dart file / project";

  @override
  bool get visible => true;
}
