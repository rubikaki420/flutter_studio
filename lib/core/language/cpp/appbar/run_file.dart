import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_studio/core/language/cpp/cpp_language.dart';

class RunFile extends AppbarActionItem {
  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    return path?.endsWith(".cpp") == true ||
        path?.endsWith(".cc") == true ||
        path?.endsWith(".cxx") == true;
  }

  @override
  Future<void> dispose() async {}

  @override
  bool get enabled => true;

  @override
  Future<dynamic> execute(EditorContext context) async {
    final language = context.language;

    if (language == null) {
      context.showMessage(message: "Language not found");
      return;
    }

    final sessionManager = language.sessionManager;

    context.bottomRegistry?.selectItemById(CPPLanguage.outputTerminalId);

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
    final name = p.basenameWithoutExtension(filePath);

    final outputBinary = p.join(dir, name);

    // compile + run C++
    await sessionManager.executeInSession(
      'editor.terminal.output_window',
      'clang++ "$filePath" -o "$outputBinary" && "$outputBinary"',
    );
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/run.png");

  @override
  String get id => "editor.cpp.appbar.run_file";

  @override
  bool isVisible(EditorContext context) => true;

  @override
  String get label => "Run";

  @override
  int get order => 0;

  @override
  Future<void> postExecute(EditorContext context, dynamic result) async {
    debugPrint("C++ execution result: $result");
  }

  @override
  Future<void> prepare(EditorContext context) async {
    await super.prepare(context);
  }

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Compile & Run C++ file";

  @override
  bool get visible => true;
}
