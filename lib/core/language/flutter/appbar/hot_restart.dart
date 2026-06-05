import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/flutter/flutter_language.dart';

class HotRestart extends AppbarActionItem {
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
  String get id => "editor.flutter.appbar.hot_restart";

  @override
  String get label => "Hot Restart";

  @override
  int get order => 2;

  @override
  Future execute(EditorContext context) async {
    final sessionManager = context.language?.sessionManager;

    if (sessionManager == null) {
      context.showMessage(message: "Terminal not initialized");
      return;
    }

    context.bottomRegistry?.selectItemById("editor.flutter.bottom.preview");

    await sessionManager.executeInSession(outputTerminalId, 'R');
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/hot_restart.png");

  @override
  Future<void> dispose() async {}

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Instance Preview with state lost";

  @override
  bool get visible => true;
}
