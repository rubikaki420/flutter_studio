import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/language.dart';

class FormatFile extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    return path?.endsWith('.py') ?? false;
  }

  @override
  bool get enabled => true;

  @override
  String get id => "editor.python.appbar.format_file";

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

    final hasBlack = await PreInstallChecker.isCommandAvailable(
      'black',
      'black',
    );

    String command;

    if (hasBlack) {
      command = 'black "$filePath"';
    } else {
      final hasAutopep8 = await PreInstallChecker.isCommandAvailable(
        'autopep8',
        'autopep8',
      );

      if (!hasAutopep8) {
        context.showMessage(
          message: "Formatter not installed. Install with: pip install black",
        );
        return;
      }

      command = 'autopep8 --in-place "$filePath"';
    }

    await sessionManager.executeInSession(outputTerminalId, command);

    context.showMessage(message: "Python file formatted");
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/format.png");

  @override
  Future<void> dispose() async {}

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Format Python file using Black";

  @override
  bool get visible => true;
}
