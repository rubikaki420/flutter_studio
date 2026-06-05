import "dart:io";
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_studio/core/language/flutter/flutter_language.dart';

class SyncProject extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final lang = context.language as FlutterLanguage?;

    if (lang == null) return false;

    if (lang.state?.isAppRunning ?? false) return false;

    final workspace = context.workspaceDirectory;
    if (workspace == null) return false;

    final pubspec = File(p.join(workspace, 'pubspec.yaml'));
    final libMain = File(p.join(workspace, 'lib', 'main.dart'));

    return pubspec.existsSync() && libMain.existsSync();
  }

  @override
  bool get enabled => true;

  @override
  String get id => "editor.flutter.appbar.sync_project";

  @override
  String get label => "Sync";

  @override
  int get order => 4;

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
      'cd ${context.workspaceDirectory!} && flutter pub get',
    );
  }

  @override
  Widget? get icon => Image.asset("assets/action_icons/sync.png");

  @override
  Future<void> dispose() async {}

  @override
  bool get requiresUIThread => false;

  @override
  String? get subtitle => "Get dependency and Sync";

  @override
  bool get visible => true;
}
