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
import 'package:re_highlight/languages/xml.dart';
import 'package:flutter_studio/core/terminal/session_manager.dart';

import 'appbar/run_file.dart';
import 'appbar/format_file.dart';
import 'bottom/preview_file.dart';
import 'html_http_server.dart';
import 'package:flutter_studio/core/sidebar/explorer/explorer_nav_item.dart';
import 'package:flutter_studio/core/sidebar/explorer/explorer_panel.dart';

import "html_language_installer.dart";

class HtmlLanguage extends Language {
  TerminalSessionManager? _sessionManager;

  HtmlHttpServer? _httpServer;

  static const String outputTerminalId = 'editor.terminal.output_window';

  @override
  TerminalSessionManager? get sessionManager => _sessionManager;

  @override
  final String languageId = 'html';

  @override
  final String displayName = 'HTML';

  @override
  List<String> get extensions => const ['html', 'htm'];

  @override
  LanguageInstaller? get installer => HtmlLanguageInstaller();

  /// HTML has no compiler — only LSP server
  @override
  String get executable => 'vscode-html-languageserver';

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
    "assets/language_icons/lang_html.png",
    width: 24,
    height: 24,
    fit: BoxFit.contain,
  );

  @override
  Mode? get mode => langXml;

  HtmlHttpServer? get httpServer => _httpServer;

  @override
  List<AppbarActionItem> getAppbarActions(EditorContext context) {
    return [...super.getAppbarActions(context), RunFile(), FormatFile()];
  }

  @override
  List<BottomItem> getBottomItems(EditorContext context) {
    return [PreviewFile()];
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
        title: 'Terminal',
        sessionId: outputTerminalId,
      );
    }

    if (context.workspaceDirectory != null) {
      _httpServer = HtmlHttpServer(rootPath: context.workspaceDirectory!);
      await _httpServer!.start();
    }
  }

  @override
  Future<void> dispose([String? workspacePath]) async {
    _sessionManager?.dispose();
    await _httpServer?.stop();
    await super.dispose(workspacePath);
  }
}
