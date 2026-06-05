import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';

class EditorTabbar extends StatelessWidget {
  final List<String> openFiles;
  final String? activeFile;
  final Function(String) onFileSelected;
  final Function(String) onFileClosed;

  const EditorTabbar({
    super.key,
    required this.openFiles,
    this.activeFile,
    required this.onFileSelected,
    required this.onFileClosed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      color: AppColors.vscodeBackground,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: openFiles.length,
        itemBuilder: (context, index) {
          final filePath = openFiles[index];
          final fileName = filePath.split('/').last;
          final isActive = filePath == activeFile;

          return GestureDetector(
            onTap: () => onFileSelected(filePath),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.vscodeBackground
                    : AppColors.transparent,
                border: Border(
                  top: BorderSide(
                    color: isActive ? AppColors.white : AppColors.transparent,
                    width: 2,
                  ),
                  right: const BorderSide(color: AppColors.overlay, width: 1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: isActive ? AppColors.text : AppColors.subtext0,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onFileClosed(filePath),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isActive ? AppColors.text : AppColors.subtext0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
