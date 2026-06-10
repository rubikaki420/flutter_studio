import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/flutter/flutter_language.dart';
import 'package:flutter_studio/core/terminal/terminal_bottom_item.dart';

class BuildProject extends AppbarActionItem {
  static const String outputTerminalId = 'editor.terminal.output_window';
  static const String _buildSuccessPattern = 'Built build';
  static const String _aabSuccessPattern = 'appbundle written';
  static const String _flutterErrorPattern = 'No command flutter found';
  static const String _buildErrorPattern = 'Error:';
  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final lang = context.language as FlutterLanguage?;
    if (lang == null) return false;

    final workspace = context.workspaceDirectory;
    if (workspace == null) return false;

    final pubspec = File('$workspace/pubspec.yaml');
    final mainFile = File('$workspace/lib/main.dart');

    return pubspec.existsSync() && mainFile.existsSync();
  }

  @override
  bool get enabled => true;

  @override
  String get id => 'editor.flutter.appbar.build_project';

  @override
  String get label => 'Build';

  @override
  int get order => 5;

  @override
  Widget? get icon => Image.asset('assets/action_icons/build.png');

  @override
  String? get subtitle => 'Build Android Project';

  @override
  bool get visible => true;

  @override
  bool get requiresUIThread => true;

  @override
  Future<void> execute(EditorContext context) async {
    final lang = context.language as FlutterLanguage?;
    final sessionManager = lang?.sessionManager;

    if (lang == null || sessionManager == null) {
      context.showMessage(message: 'Terminal not initialized');
      return;
    }

    final ctx = context.context;
    if (ctx == null) {
      context.showMessage(message: 'No UI context available');
      return;
    }

    final config = await _showBuildDialog(ctx);
    if (config == null) return;

    final workspace = context.workspaceDirectory!;
    final terminalId = outputTerminalId;

    final command = _buildCommand(config);

    lang.state?.setAppRunning(true);

    final terminal = context.bottomRegistry?.findItem(outputTerminalId);

    if (terminal is TerminalBottomItem) {
      await terminal.watchPattern(
        _buildSuccessPattern,
        onMatch: (_) {
          lang.state?.setAppRunning(false);
          context.actionsRegistry?.refresh();
          context.showMessage(message: 'Build completed successfully');
        },
      );

      await terminal.watchPattern(
        _aabSuccessPattern,
        onMatch: (_) {
          lang.state?.setAppRunning(false);
          context.actionsRegistry?.refresh();
          context.showMessage(message: 'AAB build completed successfully');
        },
      );

      await terminal.watchPattern(
        _flutterErrorPattern,
        onMatch: (_) {
          lang.state?.setAppRunning(false);
          context.actionsRegistry?.refresh();
          context.showMessage(message: 'Flutter not found');
        },
      );

      await terminal.watchPattern(
        _buildErrorPattern,
        onMatch: (_) {
          lang.state?.setAppRunning(false);
          context.actionsRegistry?.refresh();
          context.showMessage(message: 'Build failed');
        },
      );
    }

    await sessionManager.executeInSession(
      terminalId,
      'cd $workspace && clear && $command',
    );

    context.bottomRegistry?.selectItemById(terminalId);
    context.actionsRegistry?.refresh();
  }

  Future<_BuildType?> _showBuildDialog(BuildContext context) {
    return showDialog<_BuildType>(
      context: context,
      builder: (ctx) {
        _BuildType? type;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Android Build Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: const Text('Build Debug'),
                    selected: type == _BuildType.apkDebug,
                    onSelected: (_) =>
                        setState(() => type = _BuildType.apkDebug),
                  ),
                  const SizedBox(height: 10),
                  ChoiceChip(
                    label: const Text('Build Debug Split Per ABI'),
                    selected: type == _BuildType.splitAbi,
                    onSelected: (_) =>
                        setState(() => type = _BuildType.splitAbi),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: type == null
                      ? null
                      : () => Navigator.pop(ctx, type),
                  child: const Text('Build'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _buildCommand(_BuildType type) {
    switch (type) {
      case _BuildType.apkDebug:
        return 'flutter build apk --debug';
      case _BuildType.splitAbi:
        return 'flutter build apk --debug --split-per-abi';
    }
  }

  @override
  Future<void> dispose() async {}
}

enum _BuildType { apkDebug, splitAbi }
