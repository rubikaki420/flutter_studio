
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/core/widgets/home_activity_list_item.dart';
import 'package:flutter_studio/core/widgets/recent_projects_sheet.dart';
import 'package:flutter_studio/core/service/native_bridge.dart';
import 'package:flutter_studio/core/utils/project_storage.dart';
import 'package:flutter_studio/core/models/project_model.dart';
import 'package:flutter_studio/core/activities/editor_activity/editor_page.dart';
import 'package:flutter_studio/core/language/language_registry.dart';

class HomeActivity extends StatefulWidget {
  const HomeActivity({super.key});

  @override
  State<HomeActivity> createState() => _HomeActivityState();
}

class _HomeActivityState extends State<HomeActivity> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 2500));
      _checkLastProject();
    });
  }

  Future<void> _checkLastProject() async {
    final projects = await ProjectStorage.getRecentProjects();
    if (projects.isEmpty) return;

    final last = projects.first;
    final exists = Directory(last.path).existsSync();
    if (!exists) return;

    if (!mounted) return;
    _showLastProjectDialog(last);
  }

  void _showLastProjectDialog(ProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.vscodeBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.vscodeBorder),
        ),
        title: const Text(
          'Open Last Project',
          style: TextStyle(color: AppColors.white, fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Do you want to open your last project?',
              style: TextStyle(color: AppColors.vscodeLightGrey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.vscodeHover,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.vscodeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_rounded,
                          size: 14, color: AppColors.folder),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          project.path.split('/').last,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.path,
                    style: const TextStyle(
                      color: AppColors.vscodeGutter,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.code_rounded,
                          size: 12, color: AppColors.vscodeGutter),
                      const SizedBox(width: 4),
                      Text(
                        project.language,
                        style: const TextStyle(
                          color: AppColors.vscodeGutter,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.vscodeGutter, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vscodeFocus,
              foregroundColor: AppColors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openProject(project);
            },
            child: const Text('Open', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _openProject(ProjectModel project) {
    final language = LanguageRegistry.all.firstWhere(
      (l) => l.displayName == project.language,
      orElse: () => LanguageRegistry.all.first,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditorPage(
          language: language,
          workspaceDirectory: project.path,
        ),
      ),
    );
    // Persist so it shows up in recents next time
    ProjectStorage.saveProject(project.path, language.displayName);
  }

  void _showAllProjectsSheet() {
    RecentProjectsSheet.show(
      context,
      onOpen: _openProject,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languages = LanguageRegistry.all;

    return Scaffold(
      backgroundColor: AppColors.vscodeSideBar,

      appBar: AppBar(
        title: const Text("Flutter Studio"),
        backgroundColor: AppColors.vscodeBackground,
        actions: [
          IconButton(
            tooltip: 'Recent Projects',
            icon: const Icon(Icons.history_rounded),
            onPressed: _showAllProjectsSheet,
          ),
          IconButton(
            tooltip: 'Terminal',
            icon: const Icon(Icons.terminal),
            onPressed: () {
              NativeBridge.openTermuxActivity();
            },
          ),
        ],
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: languages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final language = languages[index];
          return HomeActivityListItem(
            language: language,
            onOpenRecentProjects: () {
              RecentProjectsSheet.show(
                context,
                filterLanguage: language.displayName,
                onOpen: _openProject,
              );
            },
          );
        },
      ),
    );
  }
}
