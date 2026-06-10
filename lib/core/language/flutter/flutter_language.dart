import 'dart:io';
import 'dart:convert';
import 'package:flutter_studio/core/termux_env.dart';
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
import 'package:flutter_studio/core/sidebar/explorer/explorer_nav_item.dart';
import 'package:flutter_studio/core/sidebar/explorer/explorer_panel.dart';
import 'package:flutter_studio/core/terminal/session_manager.dart';
import 'package:flutter_studio/core/language/flutter/flutter_create_project_dialog.dart';
import 'flutter_language_installer.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'appbar/run_project.dart';
import 'appbar/build_project.dart';
import 'appbar/hot_reload.dart';
import 'appbar/hot_restart.dart';
import 'appbar/stop_project.dart';
import 'appbar/sync_project.dart';
import "bottom/web_preview.dart";

class FlutterLanguage extends Language {
  bool isAppRunning = false;
  bool isAppLaunched = false;

  FlutterLanguageState? state;

  TerminalSessionManager? _sessionManager;

  static const String outputTerminalId = 'editor.terminal.output_window';
  static const String buildTerminalId = 'editor.terminal.build_window';

  @override
  TerminalSessionManager? get sessionManager => _sessionManager;

  @override
  final String languageId = 'flutter';

  @override
  final String displayName = 'Flutter';

  @override
  List<String> get extensions => const ['dart'];

  @override
  LanguageInstaller? get installer => FlutterLanguageInstaller();

  @override
  String get executable =>
      '/data/data/com.vault.fide/files/usr/opt/flutter/bin/dart';

  @override
  List<String> get args => const ["language-server", "--protocol-lsp"];

  @override
  final ActionsRegistry actionsRegistry = ActionsRegistryImpl();

  @override
  final BottomRegistry bottomRegistry = BottomRegistryImpl();

  @override
  final SidebarRegistry sidebarRegistry = SidebarRegistryImpl();

  @override
  Widget get icon => Image.asset(
    "assets/language_icons/flutter-original.png",
    width: 24,
    height: 24,
  );

  @override
  Future<void> initialize(EditorContext context) async {
    await super.initialize(context);
    state = FlutterLanguageState();
    if (context.bottomRegistry != null) {
      _sessionManager = TerminalSessionManager(context.bottomRegistry!);

      _sessionManager!.createSession(
        title: 'Flutter Output',
        sessionId: outputTerminalId,
      );
      _sessionManager!.createSession(
        title: 'Build Output',
        sessionId: buildTerminalId,
      );
    }
  }

  @override
  List<AppbarActionItem> getAppbarActions(EditorContext context) {
    return [
      ...super.getAppbarActions(context),
      RunProject(),
      HotReload(),
      HotRestart(),
      StopProject(),
      SyncProject(),
      BuildProject(),
    ];
  }

  @override
  List<BottomItem> getBottomItems(EditorContext context) {
    return [WebPreview()];
  }

  @override
  List<SidebarContribution> getSidebarItems(EditorContext context) {
    return [ExplorerNavItem(), ExplorerPanel()];
  }

  @override
  Future<void> dispose([String? workspacePath]) async {
    _sessionManager?.dispose();
    state = null;
    await super.dispose(workspacePath);
  }

  @override
  Future<String?> createProject({
    required BuildContext context,
    required String directory,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const FlutterCreateProjectDialog(),
    );

    if (result == null || !context.mounted) return null;

    final String projectName = result['name'];
    final String template = result['template'];
    final bool runPub = result['pub'];
    final bool empty = result['empty'];
    final String org = result['org'];
    final String description = result['description'];
    final List<String> platforms = List<String>.from(result['platforms']);
    final String androidLanguage = result['androidLanguage'];

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

    final flutterPath = await PreInstallChecker.resolveCommandPath('flutter');

    if (flutterPath == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Flutter not found. Please install Flutter first."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    final flutterBinDir = File(flutterPath).parent.path;

    if (!context.mounted) return null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );

    try {
      await Directory(directory).create(recursive: true);

      final args = [
        'create',
        '-t',
        template,
        '--org',
        org,
        '--description',
        description,
        '--android-language',
        androidLanguage,
        if (platforms.isNotEmpty && (template == 'app' || template == 'plugin'))
          '--platforms=${platforms.join(',')}',
        if (!runPub) '--no-pub',
        if (empty) '--empty',
        projectPath,
      ];

      final proc = await TermuxEnv.start(
        flutterPath,
        args,
        workingDirectory: directory,
        extraPaths: [flutterBinDir],
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
            content: Text(stderr.isNotEmpty ? stderr : 'flutter create failed'),
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

class FlutterLanguageState extends ChangeNotifier {
  bool _isAppRunning = false;
  bool _isAppLaunched = false;

  bool get isAppRunning => _isAppRunning;
  bool get isAppLaunched => _isAppLaunched;

  void setAppRunning(bool value) {
    _isAppRunning = value;
    notifyListeners();
  }

  void setAppLaunched(bool value) {
    _isAppLaunched = value;
    notifyListeners();
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.vscodeBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            const Text(
              "Creating Flutter Project...",
              style: TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
