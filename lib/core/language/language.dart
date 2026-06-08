import 'package:flutter/material.dart';
import 'package:flutter_studio/LSP/language_server_manager.dart';
import 'package:flutter_studio/LSP/lsp.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_registry.dart';
import 'package:re_highlight/re_highlight.dart';
import '../sidebar/sidebar_registry.dart';
import '../appbar_actions/appbar_actions_registry.dart';
import '../editor_context.dart';
import '../appbar_actions/appbar_action_item.dart';
import '../appbar_actions/standard_actions.dart';
import '../bottom_bar/bottom_item.dart';
import '../sidebar/sidebar_contribution.dart';
import 'package:flutter_studio/core/terminal/session_manager.dart';

abstract class Language {
  TerminalSessionManager? get sessionManager => null;
  String get languageId;
  String get displayName;
  List<String> get extensions => const [];
  String get executable;
  Widget get icon;
  Mode? get mode => null;
  List<String> get args => const [];
  ActionsRegistry get actionsRegistry;
  BottomRegistry get bottomRegistry;
  SidebarRegistry get sidebarRegistry;
  Future<String?> createProject({
    required BuildContext context,
    required String directory,
  }) async {
    return directory;
  }

  Future<LspConfig?> startLsp(String workspacePath) async {
    return LanguageServerManager.acquire(
      language: this,
      workspacePath: workspacePath,
    );
  }

  void stopLsp(String workspacePath) {
    LanguageServerManager.release(workspacePath);
  }

  List<AppbarActionItem> getAppbarActions(EditorContext context) {
    return [UndoAction(), RedoAction(), SaveAction()];
  }

  List<BottomItem> getBottomItems(EditorContext context) {
    return const [];
  }

  List<SidebarContribution> getSidebarItems(EditorContext context) {
    return const [];
  }

  @mustCallSuper
  Future<void> initialize(EditorContext context) async {}

  @mustCallSuper
  Future<void> dispose([String? workspacePath]) async {
    if (workspacePath != null) {
      stopLsp(workspacePath);
    }
  }
}
