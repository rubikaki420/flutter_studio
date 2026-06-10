import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/core/utils/project_storage.dart';
import 'package:flutter_studio/core/models/project_model.dart';
import 'package:path/path.dart' as p;

class RecentProjectsSheet extends StatefulWidget {
  /// If non-null, only projects matching this language are shown.
  final String? filterLanguage;

  /// Called when the user taps a project.
  final void Function(ProjectModel project) onOpen;

  const RecentProjectsSheet({
    super.key,
    this.filterLanguage,
    required this.onOpen,
  });

  // Convenience static helper so callers don't need to write showModalBottomSheet
  static Future<void> show(
    BuildContext context, {
    String? filterLanguage,
    required void Function(ProjectModel project) onOpen,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.vscodeBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (_) => RecentProjectsSheet(
        filterLanguage: filterLanguage,
        onOpen: onOpen,
      ),
    );
  }

  @override
  State<RecentProjectsSheet> createState() => _RecentProjectsSheetState();
}

class _RecentProjectsSheetState extends State<RecentProjectsSheet> {
  List<ProjectModel>? _projects;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await ProjectStorage.getRecentProjects();
    final filtered = widget.filterLanguage == null
        ? all
        : all.where((p) => p.language == widget.filterLanguage).toList();

    if (mounted) setState(() => _projects = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.filterLanguage != null ? widget.filterLanguage! : 'All Projects';

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Column(
          children: [
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: AppColors.vscodeGutter,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.vscodeLightGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      final directory =
                          await FilePicker.getDirectoryPath();
                      if (directory == null) return;
                      // Build a synthetic ProjectModel so the caller's
                      // onOpen handler can navigate to the editor.
                      widget.onOpen(
                        ProjectModel(
                          path: directory,
                          language: widget.filterLanguage ?? '',
                          timestamp: DateTime.now().toIso8601String(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.vscodeHover,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.vscodeBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.folder_open_rounded,
                              size: 14, color: AppColors.vscodeLightGrey),
                          SizedBox(width: 6),
                          Text(
                            'Open Project',
                            style: TextStyle(
                              color: AppColors.vscodeLightGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.vscodeBorder, height: 1),

            Expanded(child: _buildBody(scrollCtrl)),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollCtrl) {
    if (_projects == null) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }

    if (_projects!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_off_outlined,
              size: 36,
              color: AppColors.vscodeDarkGrey,
            ),
            const SizedBox(height: 10),
            Text(
              widget.filterLanguage != null
                  ? 'No recent ${widget.filterLanguage} projects'
                  : 'No recent projects',
              style: const TextStyle(
                color: AppColors.vscodeGutter,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _projects!.length,
      separatorBuilder: (_, _) =>
          const Divider(color: AppColors.vscodeBorder, height: 1),
      itemBuilder: (ctx, i) => _ProjectTile(
        project: _projects![i],
        onTap: () {
          Navigator.pop(ctx);
          widget.onOpen(_projects![i]);
        },
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _ProjectTile({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final exists = Directory(project.path).existsSync();
    final name = p.basename(project.path);

    return InkWell(
      onTap: exists ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              exists ? Icons.folder_rounded : Icons.folder_off_outlined,
              size: 20,
              color: exists ? AppColors.folder : AppColors.vscodeDarkGrey,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: exists
                          ? AppColors.white
                          : AppColors.vscodeDarkGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.path,
                    style: const TextStyle(
                      color: AppColors.vscodeGutter,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.vscodeHover,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.vscodeBorder),
              ),
              child: Text(
                project.language,
                style: const TextStyle(
                  color: AppColors.vscodeGutter,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            if (!exists) ...[
              const SizedBox(width: 8),
              const Tooltip(
                message: 'Folder not found',
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
