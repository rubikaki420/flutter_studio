import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/flutter/flutter_language.dart';

class StopProject extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final lang = context.language as FlutterLanguage?;

    if (lang == null) return false;

    return lang.state?.isAppLaunched ?? false;
  }

  @override
  bool get enabled => true;

  @override
  String get id => "editor.flutter.appbar.stop_project";

  @override
  String get label => "Stop";

  @override
  int get order => 3;

  @override
  Future execute(EditorContext context) async {
    final lang = context.language as FlutterLanguage?;
    final sessionManager = context.language?.sessionManager;

    if (sessionManager == null) {
      context.showMessage(message: "Terminal not initialized");
      return;
    }

    context.bottomRegistry?.selectItemById(outputTerminalId);

    await sessionManager.executeInSession(outputTerminalId, 'q');

    if (lang == null) {
      context.showMessage(message: "Terminal not initialized");
      return;
    }
    lang.state?.setAppRunning(false);
    lang.state?.setAppLaunched(false);
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/stop.png");

  @override
  Future<void> dispose() async {}

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Stop Your project";

  @override
  bool get visible => true;
}
