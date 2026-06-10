import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/LSP/language_server_manager.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/code_forge.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/language.dart';
import 'package:flutter_studio/core/language/language_registry.dart';
import 'package:flutter_studio/core/models/editor_tab_item.dart';
import 'package:flutter_studio/core/sidebar/sidebar_registry_impl.dart';
import 'package:flutter_studio/core/sidebar/sidebar_state_controller_impl.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_actions_registry_impl.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_registry_impl.dart';
import 'package:path/path.dart' as p;
import 'package:re_highlight/styles/vs2015.dart';
import 'editor_appbar.dart';
import 'editor_sidebar.dart';
import 'editor_bottom.dart';
import 'editor_tabbar.dart';
import 'editor_content.dart';

class EditorPage extends StatefulWidget {
  final Language language;
  final String workspaceDirectory;

  const EditorPage({
    super.key,
    required this.language,
    required this.workspaceDirectory,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late EditorContext _editorContext;
  late final SidebarRegistryImpl _sidebarRegistry;
  late final SidebarStateControllerImpl _sidebarController;
  late final ActionsRegistryImpl _actionsRegistry;
  late final BottomRegistryImpl _bottomRegistry;

  final List<EditorTabItem> _tabs = [];
  int _selectedIndex = -1;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _sidebarRegistry = SidebarRegistryImpl();
    _sidebarController = SidebarStateControllerImpl();
    _actionsRegistry = ActionsRegistryImpl();
    _bottomRegistry = BottomRegistryImpl();

    _editorContext = EditorContext(
      workspaceDirectory: widget.workspaceDirectory,
      context: context,
      onOpenFile: _openFile,
      bottomRegistry: _bottomRegistry,
      actionsRegistry: _actionsRegistry,
      sidebarRegistry: _sidebarRegistry,
      language: widget.language,
    );

    _initLanguage();
  }

  Future<void> _initLanguage() async {
    await widget.language.initialize(_editorContext);

    for (var action in widget.language.getAppbarActions(_editorContext)) {
      _actionsRegistry.registerAction(action);
    }

    for (var item in widget.language.getBottomItems(_editorContext)) {
      _bottomRegistry.registerItem(item);
    }

    for (var contribution in widget.language.getSidebarItems(_editorContext)) {
      _sidebarRegistry.register(contribution);
    }

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _openFile(String path) async {
    final existingIndex = _tabs.indexWhere((tab) => tab.filePath == path);
    if (existingIndex != -1) {
      final tab = _tabs[existingIndex];
      setState(() {
        _selectedIndex = existingIndex;
        _editorContext = _editorContext.copyWith(
          currentFilePath: path,
          activeCodeForgeController: tab.codeForgeController,
          activeUndoRedoController: tab.undoRedoController,
          language: widget.language,
          actionsRegistry: _actionsRegistry,
          sidebarRegistry: _sidebarRegistry,
        );
      });
      return;
    }

    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final undoController = UndoRedoController();

        final extension = p.extension(path).replaceFirst(".", "").toLowerCase();
        final fileLanguage =
            LanguageRegistry.getByExtension(extension) ?? widget.language;

        final lspConfig = await fileLanguage.startLsp(
          widget.workspaceDirectory,
        );

        final controller = CodeForgeController(lspConfig: lspConfig);
        controller.setUndoController(undoController);
        controller.text = content;

        final newTab = EditorTabItem(
          filePath: path,
          fileName: p.basename(path),
          codeForgeController: controller,
          undoRedoController: undoController,
          workspacePath: widget.workspaceDirectory,
        );

        setState(() {
          _tabs.add(newTab);
          _selectedIndex = _tabs.length - 1;
          _editorContext = _editorContext.copyWith(
            currentFilePath: path,
            activeCodeForgeController: controller,
            activeUndoRedoController: undoController,
            language: widget.language,
            actionsRegistry: _actionsRegistry,
            sidebarRegistry: _sidebarRegistry,
          );
        });
      }
    } catch (e) {
      _editorContext.showMessage(message: 'Error opening file: $e');
    }
  }

  void _closeFile(String path) {
    setState(() {
      final index = _tabs.indexWhere((tab) => tab.filePath == path);
      if (index == -1) return;

      final wasSelected = index == _selectedIndex;

      final removedTab = _tabs.removeAt(index);
      removedTab.codeForgeController.dispose();

      if (_tabs.isEmpty) {
        _selectedIndex = -1;

        _editorContext = EditorContext(
          workspaceDirectory: widget.workspaceDirectory,
          context: context,
          onOpenFile: _openFile,
          bottomRegistry: _bottomRegistry,
          actionsRegistry: _actionsRegistry,
          sidebarRegistry: _sidebarRegistry,
          language: widget.language,
        );

        return;
      }

      if (wasSelected) {
        _selectedIndex = index >= _tabs.length ? _tabs.length - 1 : index;
      } else if (index < _selectedIndex) {
        _selectedIndex--;
      }

      final currentTab = _tabs[_selectedIndex];

      _editorContext = _editorContext.copyWith(
        currentFilePath: currentTab.filePath,
        activeCodeForgeController: currentTab.codeForgeController,
        activeUndoRedoController: currentTab.undoRedoController,
        language: widget.language,
        actionsRegistry: _actionsRegistry,
        sidebarRegistry: _sidebarRegistry,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentTab = _selectedIndex != -1 ? _tabs[_selectedIndex] : null;

    return Scaffold(
      backgroundColor: AppColors.vscodeSideBar,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            EditorAppbar(
              context: _editorContext,
              actionsRegistry: _actionsRegistry,
              onMenuPressed: () {
                _sidebarController.toggleSidebar();
              },
            ),

            Expanded(
              child: Row(
                children: [
                  EditorSidebar(
                    registry: _sidebarRegistry,
                    controller: _sidebarController,
                    editorContext: _editorContext,
                  ),

                  // Main Content Area
                  Expanded(
                    child: Column(
                      children: [
                        // Tabs (HlistTabbar)
                        EditorTabbar(
                          openFiles: _tabs.map((t) => t.filePath).toList(),
                          activeFile: currentTab?.filePath,
                          onFileSelected: _openFile,
                          onFileClosed: _closeFile,
                        ),

                        // Editor Content
                        Expanded(
                          child: currentTab == null
                              ? Container(
                                  color: AppColors.vscodeSideBar,
                                  child: const Center(
                                    child: Text(
                                      "Select a file to edit",
                                      style: TextStyle(
                                        color: AppColors.overlay0,
                                      ),
                                    ),
                                  ),
                                )
                              : TabbarContent(
                                  key: ValueKey(currentTab.filePath),
                                  CodeForge(
                                    filePath: currentTab.filePath,
                                    controller: currentTab.codeForgeController,
                                    undoController:
                                        currentTab.undoRedoController,
                                    language: currentTab.mode,
                                    editorTheme: vs2015Theme,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            EditorBottomPanel(
              registry: _bottomRegistry,
              contextData: _editorContext,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    for (var tab in _tabs) {
      tab.codeForgeController.dispose();
    }
    LanguageServerManager.releaseAll(widget.workspaceDirectory);
    widget.language.dispose(widget.workspaceDirectory);
    super.dispose();
  }
}
