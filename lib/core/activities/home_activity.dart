import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/language/language_registry.dart';
import 'package:flutter_studio/core/activities/editor_activity/editor_page.dart';
import 'package:flutter_studio/core/service/native_bridge.dart';
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
    final languages = LanguageRegistry.all;
    if (languages.isEmpty) return;

    final language = languages.first;

    String? directory = await FilePicker.getDirectoryPath();
    if (directory == null || !context.mounted) return;

    final createdPath = await language.createProject(
      context: context,
      directory: directory,
    );
    if (createdPath == null || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorPage(
          language: language,
          workspaceDirectory: createdPath,
        ),
      ),
    );
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
