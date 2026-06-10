import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/language/language_registry.dart';
import 'package:flutter_studio/core/language/flutter/flutter_create_project_dialog.dart';
import 'package:flutter_studio/core/activities/editor_activity/editor_page.dart';
import 'package:flutter_studio/core/service/native_bridge.dart';
import 'package:flutter_studio/core/termux_env.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/core/widgets/home_activity_list_item.dart';

class HomeActivity extends StatelessWidget {
  const HomeActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vscodeSideBar,
      appBar: AppBar(
        title: const Text("Flutter Studio"),
        backgroundColor: AppColors.vscodeBackground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Image.asset(
              "assets/language_icons/flutter-original.png",
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Get Started",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              "Create beautiful Flutter apps",
              style: TextStyle(
                color: AppColors.subtext0,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),
          HomeActionCard(
            icon: Icons.add_circle_outline,
            title: "Create New Project",
            subtitle: "Start a new Flutter project from a template",
            onTap: () => _createProject(context),
          ),
          const SizedBox(height: 10),
          HomeActionCard(
            icon: Icons.folder_open,
            title: "Open Existing Project",
            subtitle: "Browse and open a project from your device",
            onTap: () => _openProject(context),
          ),
          const SizedBox(height: 10),
          HomeActionCard(
            icon: Icons.terminal,
            title: "Open Terminal",
            subtitle: "Open the integrated Termux terminal",
            onTap: () => NativeBridge.openTermuxActivity(),
          ),
        ],
      ),
    );
  }

  Future<void> _createProject(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const FlutterCreateProjectDialog(),
    );
    if (result == null || !context.mounted) return;

    final String projectName = result['name'];
    final String pkg = result['pkg'];

    final projectPath = '${TermuxEnv.projectsDir}/$projectName';

    if (await Directory(projectPath).exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Project '$projectName' already exists"),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    final languages = LanguageRegistry.all;
    if (languages.isEmpty) return;
    final language = languages.first;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );

    await Directory(TermuxEnv.projectsDir).create(recursive: true);

    try {
      final proc = await TermuxEnv.start(
        TermuxEnv.templateCreateBin,
        ['template-create', projectName, pkg],
        workingDirectory: TermuxEnv.projectsDir,
      );
      final exitCode = await proc.exitCode;

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (exitCode == 0) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditorPage(
              language: language,
              workspaceDirectory: projectPath,
            ),
          ),
        );
      } else {
        final stderr = await proc.stderr.transform(utf8.decoder).join();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(stderr.isNotEmpty ? stderr : "template-create failed"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _openProject(BuildContext context) async {
    final languages = LanguageRegistry.all;
    if (languages.isEmpty) return;

    final language = languages.first;

    String? directory = await FilePicker.getDirectoryPath();
    if (directory == null || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorPage(
          language: language,
          workspaceDirectory: directory,
        ),
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.vscodeBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            const Text(
              "Creating Flutter Project...",
              style: TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
