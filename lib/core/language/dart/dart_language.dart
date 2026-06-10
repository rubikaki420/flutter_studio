import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_actions_registry.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_actions_registry_impl.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_item.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_registry.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_registry_impl.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/language.dart';
import 'package:flutter_studio/core/sidebar/sidebar_contribution.dart';
import 'package:flutter_studio/core/sidebar/sidebar_registry.dart';
import 'package:flutter_studio/core/sidebar/sidebar_registry_impl.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:flutter_studio/core/terminal/session_manager.dart';
import 'appbar/run_file.dart';
import 'appbar/format_file.dart';
import 'appbar/sync_project.dart';
import 'package:flutter_studio/core/sidebar/explorer/explorer_nav_item.dart';
import 'package:flutter_studio/core/sidebar/explorer/explorer_panel.dart';
import "dart_language_installer.dart";
import 'dart_create_project_dialog.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'dart:io';
import 'dart:convert';
class DartLanguage extends Language {
  TerminalSessionManager? _sessionManager;

  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  TerminalSessionManager? get sessionManager => _sessionManager;

  @override
  final String languageId = 'dart';

  @override
  final String displayName = 'Dart';

  @override
  List<String> get extensions => const ['dart'];

  @override
  LanguageInstaller? get installer => DartLanguageInstaller();

  @override
  String get executable =>
      '/data/data/com.vault.fide/files/usr/opt/flutter/bin/dart';

  @override
  List<String> get args => const ["language-server", "--protocol=lsp"];

  @override
  final ActionsRegistry actionsRegistry = ActionsRegistryImpl();

  @override
  final BottomRegistry bottomRegistry = BottomRegistryImpl();

  @override
  final SidebarRegistry sidebarRegistry = SidebarRegistryImpl();

  @override
  Widget get icon => Image.asset(
    "assets/language_icons/dart-original.png",
    width: 24,
    height: 24,
    fit: BoxFit.contain,
  );

  @override
  Mode? get mode => langDart;

  @override
  List<AppbarActionItem> getAppbarActions(EditorContext context) {
    return [
      ...super.getAppbarActions(context),
      RunFile(),
      FormatFile(),
      SyncProject(),
    ];
  }

  @override
  List<BottomItem> getBottomItems(EditorContext context) {
    return [];
  }

  @override
  List<SidebarContribution> getSidebarItems(EditorContext context) {
    return [ExplorerNavItem(), ExplorerPanel()];
  }

  @override
  Future<void> initialize(EditorContext context) async {
    await super.initialize(context);

    if (context.bottomRegistry != null) {
      _sessionManager = TerminalSessionManager(context.bottomRegistry!);

      _sessionManager!.createSession(
        title: 'Output',
        sessionId: outputTerminalId,
      );
    }
  }

  @override
  Future<void> dispose([String? workspacePath]) async {
    _sessionManager?.dispose();
    await super.dispose(workspacePath);
  }


  @override
Future<String?> createProject({
  required BuildContext context,
  required String directory,
}) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => const DartCreateProjectDialog(),
  );

  if (result == null || !context.mounted) return null;

  final String projectName = result['name'];
  final String template = result['template'];
  final bool runPub = result['pub'];

  final projectPath = '$directory/$projectName';

  if (await Directory(projectPath).exists()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Project '$projectName' already exists"),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return null;
  }

  final dartPath = executable;

  showDialog(
          //ignore:use_build_context_synchronously
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DartLoadingDialog(),
  );

  try {
    await Directory(directory).create(recursive: true);

    final args = [
      'create',
      '--template=$template',
      if (!runPub) '--no-pub',
      projectPath,
    ];

    final proc = await Process.start(
      dartPath,
      args,
      workingDirectory: directory,
    );

    final exitCode = await proc.exitCode;

    if (!context.mounted) return null;
    Navigator.of(context).pop();

    if (exitCode == 0) {
      return projectPath;
    } else {
      final stderr = await proc.stderr.transform(utf8.decoder).join();
        //ignore:use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(stderr.isNotEmpty ? stderr : 'dart create failed'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
    return null;
  }
}
}
class _DartLoadingDialog extends StatelessWidget {
  const _DartLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.vscodeBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 20),
            Text(
              "Creating Dart Project...",
              style: TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}