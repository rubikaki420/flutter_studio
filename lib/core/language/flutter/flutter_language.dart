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

import 'appbar/run_project.dart';
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

  @override
  TerminalSessionManager? get sessionManager => _sessionManager;

  @override
  final String languageId = 'flutter';

  @override
  final String displayName = 'Flutter';

  @override
  List<String> get extensions => const ['dart'];

  @override
  String get executable => 'dart';

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
