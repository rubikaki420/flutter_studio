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
import 'package:flutter_studio/core/terminal/session_manager.dart';
import 'package:flutter_studio/core/sidebar/explorer/explorer_nav_item.dart';
import 'package:flutter_studio/core/sidebar/explorer/explorer_panel.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/python.dart';
import "appbar/run_file.dart";
import "appbar/format_file.dart";
import "appbar/sync_project.dart";
import 'python_language_installer.dart';

class PythonLanguage extends Language {
  TerminalSessionManager? _sessionManager;

  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  TerminalSessionManager? get sessionManager => _sessionManager;

  @override
  final String languageId = 'python';

  @override
  final String displayName = 'Python';

  @override
  List<String> get extensions => const ['py'];

  @override
  LanguageInstaller? get installer => PythonLanguageInstaller();

  @override
  String get executable => 'pylsp';

  @override
  List<String> get args => const [];

  @override
  final ActionsRegistry actionsRegistry = ActionsRegistryImpl();

  @override
  final BottomRegistry bottomRegistry = BottomRegistryImpl();

  @override
  final SidebarRegistry sidebarRegistry = SidebarRegistryImpl();

  @override
  Widget get icon => Image.asset(
    "assets/language_icons/lang_python.png",
    width: 24,
    height: 24,
    fit: BoxFit.contain,
  );

  @override
  Mode? get mode => langPython;

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
}
