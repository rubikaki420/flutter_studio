import 'package:flutter/material.dart';
import '../language/language.dart';
import '../activities/editor_activity/editor_page.dart';
import "install_dialog.dart";
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/core/utils/project_storage.dart';
import 'package:file_picker/file_picker.dart';
class HomeActivityListItem extends StatefulWidget {
  final Language language;

  /// Called when the user taps the "recent projects" icon on this language row.
  final VoidCallback? onOpenRecentProjects;

  const HomeActivityListItem({
    super.key,
    required this.language,
    this.onOpenRecentProjects,
  });

  @override
  State<HomeActivityListItem> createState() => _HomeActivityListItemState();
}

class _HomeActivityListItemState extends State<HomeActivityListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;
  bool isCollapsed = true;
  bool? installed;
  bool checkingInstall = true;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    loadInstallState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void toggle() {
    isCollapsed = !isCollapsed;
    isCollapsed ? controller.reverse() : controller.forward();
    setState(() {});
  }


  void _navigateToEditor(String directory) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditorPage(
          language: widget.language,
          workspaceDirectory: directory,
        ),
      ),
    );
  }

  Future<void> loadInstallState() async {
    final installer = widget.language.installer;

    if (installer == null) {
      setState(() {
        installed = true;
        checkingInstall = false;
      });
      return;
    }

    final result = await installer.isInstalled();

    if (!mounted) return;

    setState(() {
      installed = result;
      checkingInstall = false;
    });
  }

  Future<void> showInstallDialog() async {
    final installer = widget.language.installer;

    if (installer == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return InstallDialog(
          installer: installer,
          onInstalled: () {
            if (!mounted) return;
            setState(() {
              installed = true;
            });
          },
        );
      },
    );
  }

  Widget buildInstallBadge() {
    if (checkingInstall) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final isInstalled = installed ?? false;

    return InkWell(
      onTap: isInstalled ? null : showInstallDialog,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isInstalled ? AppColors.blueGrey : AppColors.orange,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          isInstalled ? 'Installed' : 'Not Installed',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  Future<String?> _openDirectory() async {
    String? directory = await FilePicker.getDirectoryPath();
    return directory;
  }

  @override
  Widget build(BuildContext context) {
    var language = widget.language;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.vscodeBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: toggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  language.icon,

                  const SizedBox(width: 12),

                  Text(
                    language.displayName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 12),

                  AnimatedRotation(
                    turns: isCollapsed ? 0 : 0.5,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.white,
                    ),
                  ),

                  const Spacer(),

                  buildInstallBadge(),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: animation,
            child: Row(
              children: [
                // ── Open Existing ──────────────────────────────
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onOpenRecentProjects?.call(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: const Text(
                        "Open Existing Project",
                        style: TextStyle(color: AppColors.white),
                      ),
                    ),
                  ),
                ),

                // ── Create New ────────────────────────────────
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      String? directory = await _openDirectory();
                      if (directory == null) return;
                      //ignore: use_build_context_synchronously
                      final createdPath = await language.createProject(
                        //ignore: use_build_context_synchronously
                        context: context,
                        directory: directory,
                      );
                      if (createdPath == null) return;
                      await ProjectStorage.saveProject(
                          directory, widget.language.displayName);
                      _navigateToEditor(createdPath);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: AppColors.blue,
                      alignment: Alignment.center,
                      child: Text(
                          "Create new ${language.displayName} project"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
