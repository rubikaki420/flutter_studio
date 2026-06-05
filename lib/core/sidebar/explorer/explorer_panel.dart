import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/sidebar/sidebar_panel.dart';
import 'package:flutter_studio/widgets/flutter_treeview.dart';
import 'package:path/path.dart' as p;

class ExplorerPanel extends SidebarPanel {
  @override
  String get id => 'universal.explorer.panel';

  @override
  int get order => 0;

  @override
  Widget build(BuildContext context, EditorContext editorContext) {
    return _ExplorerView(editorContext: editorContext);
  }
}

List<FileSystemEntity> _listDir(String path) {
  try {
    return Directory(path).listSync()..sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase());
    });
  } catch (_) {
    return [];
  }
}

const _kFolderColor = AppColors.folder;
const _kCColor = AppColors.cFile;
const _kHColor = AppColors.hFile;
const _kDartColor = AppColors.dartFile;
const _kYamlColor = AppColors.yamlFile;
const _kMdColor = AppColors.mdFile;
const _kJsonColor = AppColors.jsonFile;
const _kImgColor = AppColors.imgFile;
const _kCppColor = AppColors.cppFile;
const _kJsColor = AppColors.jsFile;
const _kTsColor = AppColors.tsFile;
const _kPythonColor = AppColors.pythonFile;
const _kDefaultColor = AppColors.defaultFile;

Color _fileColor(FileSystemEntity e) {
  if (e is Directory) return _kFolderColor;
  final ext = p.extension(e.path).replaceFirst('.', '').toLowerCase();
  return switch (ext) {
    'c' => _kCColor,
    'h' || 'hpp' => _kHColor,
    'cpp' || 'cc' => _kCppColor,
    'dart' => _kDartColor,
    'js' => _kJsColor,
    'ts' => _kTsColor,
    'py' => _kPythonColor,
    'yaml' || 'yml' => _kYamlColor,
    'md' => _kMdColor,
    'json' => _kJsonColor,
    'png' || 'jpg' || 'jpeg' || 'svg' || 'webp' => _kImgColor,
    _ => _kDefaultColor,
  };
}

IconData _fileIcon(FileSystemEntity e, bool expanded) {
  if (e is Directory) {
    return expanded ? Icons.folder_open_rounded : Icons.folder_rounded;
  }
  final ext = p.extension(e.path).replaceFirst('.', '').toLowerCase();
  return switch (ext) {
    'c' || 'h' || 'hpp' || 'cpp' || 'cc' => Icons.terminal_rounded,
    'dart' || 'js' || 'ts' || 'py' => Icons.code_rounded,
    'md' => Icons.article_outlined,
    'yaml' || 'yml' => Icons.settings_outlined,
    'json' => Icons.data_object_rounded,
    'png' || 'jpg' || 'jpeg' || 'svg' || 'webp' => Icons.image_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

class _ExplorerView extends StatefulWidget {
  final EditorContext editorContext;
  const _ExplorerView({required this.editorContext});

  @override
  State<_ExplorerView> createState() => _ExplorerViewState();
}

class _ExplorerViewState extends State<_ExplorerView> {
  TreeNode<FileSystemEntity>? _root;
  TreeNode<FileSystemEntity>? _selectedNode;
  bool _loading = true;

  // For inline rename
  TreeNode<FileSystemEntity>? _renamingNode;
  final _renameCtrl = TextEditingController();
  final _renameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadRoot();
  }

  @override
  void dispose() {
    _renameCtrl.dispose();
    _renameFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRoot() async {
    final dirPath = widget.editorContext.workspaceDirectory;
    if (dirPath == null) return;

    final entries = await compute(_listDir, dirPath);
    final root = TreeNode<FileSystemEntity>(
      value: Directory(dirPath),
      isExpanded: true,
      childrenLoaded: true,
    );
    for (final e in entries) {
      root.addChild(_makeNode(e));
    }

    if (mounted)
      setState(() {
        _root = root;
        _loading = false;
      });
  }

  TreeNode<FileSystemEntity> _makeNode(FileSystemEntity e) {
    final node = TreeNode<FileSystemEntity>(value: e);
    // Directories: mark as not loaded (lazy). Add a dummy child so the
    // expand arrow is visible.
    if (e is Directory) {
      try {
        if (e.listSync().isNotEmpty) {
          node.addChild(
            TreeNode<FileSystemEntity>(value: File('__placeholder__')),
          );
        } else {
          node.childrenLoaded = true; // empty dir, nothing to load
        }
      } catch (_) {
        node.childrenLoaded = true;
      }
    } else {
      node.childrenLoaded = true;
    }
    return node;
  }

  Future<void> _expandNode(TreeNode<FileSystemEntity> node) async {
    if (node.value is! Directory) return;
    final entries = await compute(_listDir, node.value.path);
    node.deleteAllChildren();
    for (final e in entries) {
      node.addChild(_makeNode(e));
    }
    node.childrenLoaded = true;
  }

  void _refresh() {
    setState(() {
      _root = null;
      _loading = true;
    });
    _loadRoot();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    final name = p.basename(
      widget.editorContext.workspaceDirectory ?? 'EXPLORER',
    );

    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.vscodeBackground,
      child: Row(
        children: [
          Expanded(
            child: Text(
              name.toUpperCase(),
              style: const TextStyle(
                color: AppColors.vscodeGrey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _headerBtn(Icons.note_add_outlined, 'New File', _newFileAtRoot),
          _headerBtn(
            Icons.create_new_folder_outlined,
            'New Folder',
            _newFolderAtRoot,
          ),
          _headerBtn(Icons.refresh_rounded, 'Refresh', _refresh),
          _headerBtn(Icons.unfold_less_rounded, 'Collapse All', _collapseAll),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 600),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 16, color: AppColors.vscodeGutter),
          ),
        ),
      );

  final _treeKey = GlobalKey<TreeViewState>();

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    if (_root == null) {
      return const Center(
        child: Text(
          'No folder open',
          style: TextStyle(color: AppColors.vscodeGutter, fontSize: 13),
        ),
      );
    }

    return TreeView<FileSystemEntity>(
      key: _treeKey,
      root: _root!,
      showTopNode: false,
      use2dScroll: true,
      indentWidth: 8,
      padding: const EdgeInsets.only(bottom: 16),
      onNodeExpand: _expandNode,
      onNodeTap: (node) {
        setState(() => _selectedNode = node);
        if (node.value is File &&
            !node.value.path.contains('__placeholder__')) {
          widget.editorContext.openFile(node.value.path);
        }
      },
      onNodeLongPress: (node) => _showContextMenu(context, node),
      builder: _buildNodeRow,
    );
  }

  Widget _buildNodeRow(BuildContext ctx, TreeNode<FileSystemEntity> node) {
    // Hide placeholder nodes
    if (node.value.path.contains('__placeholder__')) {
      return const SizedBox.shrink();
    }

    final isSelected = _selectedNode?.id == node.id;
    final isDir = node.value is Directory;
    final name = p.basename(node.value.path);

    // Inline rename mode
    if (_renamingNode?.id == node.id) {
      return _buildRenameField(node);
    }

    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.vscodeSelection : AppColors.transparent,
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // File icon
          Icon(
            _fileIcon(node.value, node.isExpanded),
            size: 16,
            color: _fileColor(node.value),
          ),
          const SizedBox(width: 6),
          // Name
          Text(
            name,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.vscodeLightGrey,
              fontSize: 13,
              fontWeight: isDir ? FontWeight.w500 : FontWeight.normal,
              fontFamily: 'monospace',
            ),
          ),
          // Loading indicator for this node
          if (node.isLoading) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRenameField(TreeNode<FileSystemEntity> node) {
    return SizedBox(
      height: 22,
      width: 180,
      child: TextField(
        controller: _renameCtrl,
        focusNode: _renameFocus,
        style: const TextStyle(
          color: AppColors.vscodeLightGrey,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 3,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: AppColors.vscodeFocus),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(
              color: AppColors.vscodeFocus,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: AppColors.vscodeHover,
        ),
        onSubmitted: (val) => _commitRename(node, val),
        onEditingComplete: () {},
      ),
    );
  }

  void _showContextMenu(
    BuildContext ctx,
    TreeNode<FileSystemEntity> node,
  ) async {
    // Get tap position for desktop; use bottom-sheet for mobile
    final isDir = node.value is Directory;

    if (Theme.of(ctx).platform == TargetPlatform.android ||
        Theme.of(ctx).platform == TargetPlatform.iOS) {
      _showMobileContextMenu(ctx, node, isDir);
    } else {
      _showDesktopContextMenu(ctx, node, isDir);
    }
  }

  void _showDesktopContextMenu(
    BuildContext ctx,
    TreeNode<FileSystemEntity> node,
    bool isDir,
  ) {
    final RenderBox overlay =
        Overlay.of(ctx).context.findRenderObject() as RenderBox;

    showMenu(
      context: ctx,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          overlay.localToGlobal(Offset.zero),
          overlay.localToGlobal(overlay.size.bottomRight(Offset.zero)),
        ),
        Offset.zero & overlay.size,
      ),
      color: AppColors.vscodeBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppColors.vscodeBorder),
      ),
      items: _contextItems(ctx, node, isDir),
    );
  }

  void _showMobileContextMenu(
    BuildContext ctx,
    TreeNode<FileSystemEntity> node,
    bool isDir,
  ) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.vscodeBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.vscodeDarkGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                p.basename(node.value.path),
                style: const TextStyle(
                  color: AppColors.vscodeLightGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(color: AppColors.vscodeBorder, height: 1),
            ..._contextItemWidgets(ctx, node, isDir),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry> _contextItems(
    BuildContext ctx,
    TreeNode<FileSystemEntity> node,
    bool isDir,
  ) {
    return [
      if (isDir) ...[
        _menuItem(
          ctx,
          Icons.note_add_outlined,
          'New File',
          () => _newFileIn(ctx, node),
        ),
        _menuItem(
          ctx,
          Icons.create_new_folder_outlined,
          'New Folder',
          () => _newFolderIn(ctx, node),
        ),
        const PopupMenuDivider(height: 1),
      ],
      _menuItem(
        ctx,
        Icons.content_copy_rounded,
        'Copy Path',
        () => _copyPath(node),
      ),
      const PopupMenuDivider(height: 1),
      _menuItem(
        ctx,
        Icons.drive_file_rename_outline_rounded,
        'Rename',
        () => _startRename(node),
      ),
      _menuItem(
        ctx,
        Icons.delete_outline_rounded,
        'Delete',
        () => _confirmDelete(ctx, node),
        color: AppColors.error,
      ),
    ];
  }

  List<Widget> _contextItemWidgets(
    BuildContext ctx,
    TreeNode<FileSystemEntity> node,
    bool isDir,
  ) {
    void wrap(VoidCallback fn) {
      Navigator.pop(ctx);
      fn();
    }

    final items = <Widget>[
      if (isDir) ...[
        _mobileMenuItem(
          Icons.note_add_outlined,
          'New File',
          () => wrap(() => _newFileIn(ctx, node)),
        ),
        _mobileMenuItem(
          Icons.create_new_folder_outlined,
          'New Folder',
          () => wrap(() => _newFolderIn(ctx, node)),
        ),
        const Divider(color: AppColors.vscodeBorder, height: 1),
      ],
      _mobileMenuItem(
        Icons.content_copy_rounded,
        'Copy Path',
        () => wrap(() => _copyPath(node)),
      ),
      const Divider(color: AppColors.vscodeBorder, height: 1),
      _mobileMenuItem(
        Icons.drive_file_rename_outline_rounded,
        'Rename',
        () => wrap(() => _startRename(node)),
      ),
      _mobileMenuItem(
        Icons.delete_outline_rounded,
        'Delete',
        () => wrap(() => _confirmDelete(ctx, node)),
        color: AppColors.error,
      ),
    ];
    return items;
  }

  PopupMenuItem _menuItem(
    BuildContext ctx,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) => PopupMenuItem(
    onTap: onTap,
    height: 32,
    child: Row(
      children: [
        Icon(icon, size: 15, color: color ?? AppColors.vscodeLightGrey),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color ?? AppColors.vscodeLightGrey,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );

  Widget _mobileMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) => ListTile(
    dense: true,
    leading: Icon(icon, size: 18, color: color ?? AppColors.vscodeLightGrey),
    title: Text(
      label,
      style: TextStyle(color: color ?? AppColors.vscodeLightGrey, fontSize: 14),
    ),
    onTap: onTap,
  );

  void _newFileAtRoot() {
    if (_root == null) return;
    _newFileIn(context, _root!);
  }

  void _newFolderAtRoot() {
    if (_root == null) return;
    _newFolderIn(context, _root!);
  }

  void _newFileIn(BuildContext ctx, TreeNode<FileSystemEntity> node) {
    final dirPath = node.value is Directory
        ? node.value.path
        : p.dirname(node.value.path);
    _nameDialog(ctx, 'New File', 'filename.ext', (name) {
      File(p.join(dirPath, name)).createSync();
      _refresh();
    });
  }

  void _newFolderIn(BuildContext ctx, TreeNode<FileSystemEntity> node) {
    final dirPath = node.value is Directory
        ? node.value.path
        : p.dirname(node.value.path);
    _nameDialog(ctx, 'New Folder', 'folder', (name) {
      Directory(p.join(dirPath, name)).createSync(recursive: true);
      _refresh();
    });
  }

  void _copyPath(TreeNode<FileSystemEntity> node) {
    Clipboard.setData(ClipboardData(text: node.value.path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Path copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startRename(TreeNode<FileSystemEntity> node) {
    _renameCtrl.text = p.basename(node.value.path);
    setState(() => _renamingNode = node);
    Future.microtask(() {
      _renameFocus.requestFocus();
      _renameCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _renameCtrl.text.lastIndexOf('.') > 0
            ? _renameCtrl.text.lastIndexOf('.')
            : _renameCtrl.text.length,
      );
    });
  }

  void _commitRename(TreeNode<FileSystemEntity> node, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == p.basename(node.value.path)) {
      setState(() => _renamingNode = null);
      return;
    }
    try {
      final newPath = p.join(p.dirname(node.value.path), trimmed);
      node.value.renameSync(newPath);
    } catch (e) {
      _showError('Rename failed: $e');
    }
    setState(() => _renamingNode = null);
    _refresh();
  }

  void _confirmDelete(BuildContext ctx, TreeNode<FileSystemEntity> node) {
    final name = p.basename(node.value.path);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.vscodeBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.vscodeBorder),
        ),
        title: const Text(
          'Delete',
          style: TextStyle(color: AppColors.white, fontSize: 15),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: const TextStyle(
            color: AppColors.vscodeLightGrey,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.vscodeGutter),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              try {
                node.value.deleteSync(recursive: true);
              } catch (e) {
                _showError('Delete failed: $e');
              }
              _refresh();
            },
            child: const Text('Delete', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _collapseAll() {
    _treeKey.currentState?.collapseAll();
    setState(() {});
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  // ── Name dialog (used for new file/folder) ──────────────

  void _nameDialog(
    BuildContext ctx,
    String title,
    String hint,
    void Function(String) onConfirm,
  ) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.vscodeBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.vscodeBorder),
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.white, fontSize: 15),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(
            color: AppColors.vscodeLightGrey,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.vscodeDarkGrey,
              fontSize: 13,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: AppColors.vscodeFocus),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: AppColors.vscodeFocus,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: AppColors.vscodeHover,
          ),
          onSubmitted: (val) {
            if (val.trim().isEmpty) return;
            Navigator.pop(ctx);
            onConfirm(val.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.vscodeGutter, fontSize: 13),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vscodeFocus,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              onConfirm(ctrl.text.trim());
            },
            child: const Text('OK', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
