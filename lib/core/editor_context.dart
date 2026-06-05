import 'package:flutter/material.dart';
import 'package:flutter_studio/code_forge.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_registry.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_actions_registry.dart';
import 'package:flutter_studio/core/sidebar/sidebar_registry.dart';
import 'package:flutter_studio/core/language/language.dart';

typedef OpenFileCallback = void Function(String path);

/// Now it is dummy. just for testing
class EditorContext {
  final String? workspaceDirectory;
  final BuildContext? context;
  final String? currentFilePath;
  final OpenFileCallback? onOpenFile;
  final CodeForgeController? activeCodeForgeController;
  final UndoRedoController? activeUndoRedoController;
  final BottomRegistry? bottomRegistry;
  final ActionsRegistry? actionsRegistry;
  final SidebarRegistry? sidebarRegistry;
  final Language? language;

  const EditorContext({
    this.workspaceDirectory = "/storage/emulated/0/Tmp/flutter_studio/",
    this.context,
    this.currentFilePath,
    this.onOpenFile,
    this.activeCodeForgeController,
    this.activeUndoRedoController,
    this.bottomRegistry,
    this.actionsRegistry,
    this.sidebarRegistry,
    this.language,
  });

  void showMessage({String? message, Widget? content}) {
    if (context != null) {
      ScaffoldMessenger.of(
        context!,
      ).showSnackBar(SnackBar(content: content ?? Text(message ?? "")));
    }
  }

  void openFile(String path) {
    onOpenFile?.call(path);
  }

  EditorContext copyWith({
    String? workspaceDirectory,
    BuildContext? context,
    String? currentFilePath,
    OpenFileCallback? onOpenFile,
    CodeForgeController? activeCodeForgeController,
    UndoRedoController? activeUndoRedoController,
    BottomRegistry? bottomRegistry,
    ActionsRegistry? actionsRegistry,
    SidebarRegistry? sidebarRegistry,
    Language? language,
  }) {
    return EditorContext(
      workspaceDirectory: workspaceDirectory ?? this.workspaceDirectory,
      context: context ?? this.context,
      currentFilePath: currentFilePath ?? this.currentFilePath,
      onOpenFile: onOpenFile ?? this.onOpenFile,
      activeCodeForgeController:
          activeCodeForgeController ?? this.activeCodeForgeController,
      activeUndoRedoController:
          activeUndoRedoController ?? this.activeUndoRedoController,
      bottomRegistry: bottomRegistry ?? this.bottomRegistry,
      actionsRegistry: actionsRegistry ?? this.actionsRegistry,
      sidebarRegistry: sidebarRegistry ?? this.sidebarRegistry,
      language: language ?? this.language,
    );
  }
}
