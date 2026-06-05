import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_actions_registry.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_actions_registry_impl.dart';
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

import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/javascript.dart';

import 'js_language_installer.dart';

import 'appbar/run_file.dart';
import 'appbar/format_file.dart';
import 'appbar/sync_project.dart';

class JsLanguage extends Language {
  TerminalSessionManager? _sessionManager;

  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  TerminalSessionManager? get sessionManager => _sessionManager;

  @override
  final String languageId = 'javascript';

  @override
  final String displayName = 'JavaScript';

  @override
  List<String> get extensions => const ['js', 'mjs', 'cjs'];

  @override
  LanguageInstaller? get installer => JsLanguageInstaller();

  @override
  String get executable => 'typescript-language-server';

  @override
  List<String> get args => const ['--stdio'];

  @override
  final ActionsRegistry actionsRegistry = ActionsRegistryImpl();

  @override
  final BottomRegistry bottomRegistry = BottomRegistryImpl();

  @override
  final SidebarRegistry sidebarRegistry = SidebarRegistryImpl();

  @override
  Widget get icon => Image.asset(
    "assets/language_icons/lang_javascript.png",
    width: 24,
    height: 24,
  );

  @override
  Mode? get mode => langJavascript;

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
  List<AppbarActionItem> getAppbarActions(EditorContext context) {
    return [
      ...super.getAppbarActions(context),
      RunFile(),
      FormatFile(),
      SyncProject(),
    ];
  }

  @override
  List<SidebarContribution> getSidebarItems(EditorContext context) {
    return [ExplorerNavItem(), ExplorerPanel()];
  }
}
