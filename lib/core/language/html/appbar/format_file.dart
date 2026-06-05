//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/language.dart';
//import 'package:path/path.dart' as p;

class FormatFile extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    return path?.endsWith('.html') == true || path?.endsWith('.htm') == true;
  }

  @override
  bool get enabled => true;

  @override
  String get id => "editor.html.appbar.format_file";

  @override
  String get label => "Format";

  @override
  int get order => 1;

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

    // PreInstallChecker ব্যবহার করে সরাসরি চেক
    final hasPrettier = await PreInstallChecker.isCommandAvailable(
      'prettier',
      'prettier',
    );

    if (!hasPrettier) {
      context.showMessage(
        message: "Prettier not installed. Run: npm i -g prettier",
      );
      return;
    }

    final command = 'prettier --write "$filePath"';

    await sessionManager.executeInSession(outputTerminalId, command);
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/format.png");

  @override
  Future<void> dispose() async {}

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Format HTML file using Prettier";

  @override
  bool get visible => true;
}
