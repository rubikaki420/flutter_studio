import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/terminal/terminal_bottom_item.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_studio/core/language/flutter/flutter_language.dart';

class RunProject extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';
  static const String _flutterReadyPattern = 'is being served at';
  static const String _flutterErrorPattern = 'No command flutter found';
  //static const String _flutterErrorPattern = 'Not show in terminal so test it';

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
    final mainFile = File(p.join(workspace, 'lib', 'main.dart'));
    return pubspec.existsSync() && mainFile.existsSync();
  }

  @override
  bool get enabled => true;

  @override
  String get id => 'editor.flutter.appbar.run_project';

  @override
  String get label => 'Run';

  @override
  int get order => 0;

  @override
  Widget? get icon => Image.asset('assets/action_icons/run.png');

  @override
  String? get subtitle => 'Run Your project';

  @override
  bool get visible => true;

  @override
  bool get requiresUIThread => false;

  @override
  Future<void> execute(EditorContext context) async {
    final lang = context.language as FlutterLanguage?;
    final sessionManager = lang?.sessionManager;

    if (sessionManager == null || lang == null) {
      context.showMessage(message: 'Terminal not initialized');
      return;
    }

    lang.state?.setAppRunning(true);

    final terminal = context.bottomRegistry?.findItem(outputTerminalId);

    if (terminal is TerminalBottomItem) {
      await terminal.watchPattern(
        _flutterReadyPattern,
        onMatch: (_) {
          lang.state?.setAppLaunched(true);
          context.actionsRegistry?.refresh();
        },
      );

      await terminal.watchPattern(
        _flutterErrorPattern,
        onMatch: (_) {
          lang.state?.setAppRunning(false);
          context.actionsRegistry?.refresh();
          context.showMessage(
            message: 'flutter command not found. Is Flutter installed?',
          );
        },
      );
    }

    context.bottomRegistry?.selectItemById(outputTerminalId);

    await sessionManager.executeInSession(
      outputTerminalId,
      'cd ${context.workspaceDirectory!} && clear && flutter run -d web-server --web-port 8080',
    );
  }

  @override
  Future<void> dispose() async {}
}
