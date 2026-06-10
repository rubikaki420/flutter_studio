import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';

class DartCreateProjectDialog extends StatefulWidget {
  const DartCreateProjectDialog({super.key});

  @override
  State<DartCreateProjectDialog> createState() =>
      _DartCreateProjectDialogState();
}

class _DartCreateProjectDialogState extends State<DartCreateProjectDialog> {
  final _nameController = TextEditingController(text: 'my_dart_app');
  String _selectedTemplate = 'console';
  bool _runPub = true;

  static const _templates = [
    ('console', 'Console App', 'Default command-line application'),
    ('cli', 'CLI App', 'With argument parsing'),
    ('package', 'Package', 'Shared Dart libraries'),
    ('server-shelf', 'Server (Shelf)', 'HTTP server using package:shelf'),
    ('web', 'Web App', 'Core Dart libraries only'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.vscodeBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Dart Project',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Project Name',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Template',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ..._templates.map(
                  (t) => _TemplateOption(
                    value: t.$1,
                    label: t.$2,
                    description: t.$3,
                    selected: _selectedTemplate == t.$1,
                    onTap: () => setState(() => _selectedTemplate = t.$1),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Switch(
                      value: _runPub,
                      onChanged: (v) => setState(() => _runPub = v),
                      //activeColor: AppColors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Run pub get after creation',
                        style: const TextStyle(color: AppColors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                      ),
                      onPressed: () {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) return;
                        Navigator.of(context).pop({
                          'name': name,
                          'template': _selectedTemplate,
                          'pub': _runPub,
                        });
                      },
                      child: const Text(
                        'Create',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateOption extends StatelessWidget {
  final String value, label, description;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateOption({
    required this.value,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue.withValues(alpha: 0.2)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.blue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.blue, size: 18),
          ],
        ),
      ),
    );
  }
}
