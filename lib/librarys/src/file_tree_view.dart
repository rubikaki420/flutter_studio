import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_studio/util/file_icons.dart';
import 'package:flutter_studio/librarys/style.dart';
import 'tree_view.dart';
import 'models/tree_node.dart';

class DirectoryTreeViewer extends StatefulWidget {
  final String rootPath;
  final bool isUnfoldedFirst;
  final bool enableCreateFolderOption;
  final bool enableCreateFileOption;
  final bool enableDeleteFolderOption;
  final bool enableDeleteFileOption;
  final FolderStyle? folderStyle;
  final FileStyle? fileStyle;
  final EditingFieldStyle? editingFieldStyle;
  final void Function(File, TapDownDetails)? onFileTap;
  final void Function(File, TapDownDetails)? onFileSecondaryTap;
  final void Function(Directory, TapDownDetails)? onDirTap;
  final void Function(Directory, TapDownDetails)? onDirSecondaryTap;

  const DirectoryTreeViewer({
    super.key,
    required this.rootPath,
    this.isUnfoldedFirst = true,
    this.enableCreateFolderOption = false,
    this.enableCreateFileOption = true,
    this.enableDeleteFolderOption = true,
    this.enableDeleteFileOption = true,
    this.folderStyle,
    this.fileStyle,
    this.editingFieldStyle,
    this.onFileTap,
    this.onFileSecondaryTap,
    this.onDirTap,
    this.onDirSecondaryTap,
  });

  @override
  State<DirectoryTreeViewer> createState() => _DirectoryTreeViewerState();
}

class _DirectoryTreeViewerState extends State<DirectoryTreeViewer> {
  late TreeNode<FileSystemEntity> _rootNode;
  StreamSubscription<FileSystemEvent>? _directoryWatcher;

  @override
  void initState() {
    super.initState();
    _refreshTree();
    _startWatching();
  }

  @override
  void dispose() {
    _directoryWatcher?.cancel();
    super.dispose();
  }

  void _refreshTree() {
    setState(() {
      _rootNode = TreeNode<FileSystemEntity>(
        value: Directory(widget.rootPath),
        isExpanded: widget.isUnfoldedFirst,
      );
      _populateNode(_rootNode);
    });
  }

  void _startWatching() {
    _directoryWatcher?.cancel();
    final dir = Directory(widget.rootPath);
    if (dir.existsSync()) {
      _directoryWatcher = dir.watch(recursive: true).listen((event) {
        _refreshTree();
      });
    }
  }

  void _populateNode(TreeNode<FileSystemEntity> node) {
    final entity = node.value;
    if (entity is Directory) {
      try {
        final entities = entity.listSync();
        entities.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.compareTo(b.path);
        });
        for (var e in entities) {
          final childNode = TreeNode<FileSystemEntity>(value: e);
          node.addChild(childNode);
          if (e is Directory) {
            _populateNode(childNode);
          }
        }
      } catch (e) {
        // Silently ignore errors
      }
    }
  }

  Future<void> _showCreateRenameDialog({
    required FileSystemEntity entity,
    bool isFolder = false,
    bool isRename = false,
  }) async {
    final controller = TextEditingController();
    if (isRename) {
      controller.text = path.basename(entity.path);
    }

    final String title = isRename
        ? 'Rename ${entity is Directory ? 'Folder' : 'File'}'
        : 'Create New ${isFolder ? 'Folder' : 'File'}';
    final String buttonText = isRename ? 'Rename' : 'Create';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: isFolder ? 'Folder Name' : 'File Name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(buttonText),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  try {
                    if (isRename) {
                      final newPath = path.join(entity.parent.path, name);
                      entity.renameSync(newPath);
                    } else {
                      final newPath = path.join(entity.path, name);
                      if (isFolder) {
                        Directory(newPath).createSync();
                      } else {
                        File(newPath).createSync();
                      }
                    }
                    if (mounted) {
                      _refreshTree();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showBottomSheet(FileSystemEntity entity) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        final isDirectory = entity is Directory;

        bool showDeleteOption = false;
        if (entity is File && widget.enableDeleteFileOption) {
          showDeleteOption = true;
        } else if (isDirectory && widget.enableDeleteFolderOption) {
          showDeleteOption = true;
        }

        return Wrap(
          children: <Widget>[
            if (showDeleteOption)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);

                  final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: Text(
                          'Are you sure you want to delete ${path.basename(entity.path)}? This action cannot be undone.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmDelete == true) {
                    try {
                      entity.deleteSync(recursive: true);
                      if (mounted) {
                        _refreshTree();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error deleting ${path.basename(entity.path)}: $e',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            if (isDirectory) ...[
              if (widget.enableCreateFileOption)
                ListTile(
                  leading: const Icon(Icons.note_add),
                  title: const Text('New file'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showCreateRenameDialog(entity: entity, isFolder: false);
                  },
                ),
              if (widget.enableCreateFolderOption)
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: const Text('New folder'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showCreateRenameDialog(entity: entity, isFolder: true);
                  },
                ),
            ],
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showCreateRenameDialog(entity: entity, isRename: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy path'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                Clipboard.setData(ClipboardData(text: entity.path));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TreeView<FileSystemEntity>(
      root: _rootNode,
      builder: (context, node) {
        final entity = node.value;
        final isDirectory = entity is Directory;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            children: [
              if (isDirectory)
                _buildFolderArrow(node)
              else
                const SizedBox(width: 24),
              
              const SizedBox(width: 4),
              
              if (isDirectory)
                _getFolderIcon(node)
              else
                getIconForFile(entity as File),
                
              const SizedBox(width: 8),
              
              Expanded(
                child: Text(
                  path.basename(entity.path),
                  style: isDirectory 
                      ? (widget.folderStyle?.folderNameStyle ?? const TextStyle(fontSize: 14))
                      : (widget.fileStyle?.fileNameStyle ?? const TextStyle(fontSize: 14)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      onNodeTap: (node) {
        final entity = node.value;
        if (entity is File) {
          if (widget.onFileTap != null) {
            widget.onFileTap!(entity, TapDownDetails());
          }
        } else if (entity is Directory) {
          if (widget.onDirTap != null) {
            widget.onDirTap!(entity, TapDownDetails());
          }
        }
      },
      onNodeLongPress: (node) {
        _showBottomSheet(node.value);
      },
    );
  }

  Widget _buildFolderArrow(TreeNode<FileSystemEntity> node) {
    if (node.isRoot) {
      return node.isExpanded 
          ? (widget.folderStyle?.rootFolderOpenedIcon ?? const Icon(Icons.arrow_drop_down, size: 20))
          : (widget.folderStyle?.rootFolderClosedIcon ?? const Icon(Icons.arrow_right, size: 20));
    }
    return node.isExpanded 
        ? (widget.folderStyle?.folderOpenedicon ?? const Icon(Icons.arrow_drop_down, size: 20))
        : (widget.folderStyle?.folderClosedicon ?? const Icon(Icons.arrow_right, size: 20));
  }
  
  Widget _getFolderIcon(TreeNode<FileSystemEntity> node) {
    return Icon(
      node.isExpanded ? Icons.folder_open : Icons.folder,
      color: Colors.amber,
      size: 20,
    );
  }
}
