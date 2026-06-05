import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';

class FlutterCreateProjectDialog extends StatefulWidget {
  const FlutterCreateProjectDialog({super.key});

  @override
  State<FlutterCreateProjectDialog> createState() =>
      _FlutterCreateProjectDialogState();
}

class _FlutterCreateProjectDialogState
    extends State<FlutterCreateProjectDialog> {
  final _nameController = TextEditingController(text: 'my_flutter_app');
  final _orgController = TextEditingController(text: 'com.example');
  final _descController = TextEditingController(text: 'A new Flutter project.');

  String _template = 'app';
  String _androidLanguage = 'kotlin';
  bool _runPub = true;
  bool _empty = false;

  final List<String> _selectedPlatforms = ['android', 'ios', 'web'];

  static const _templates = [
    ('app', 'App', 'Flutter application'),
    ('module', 'Module', 'Add Flutter to existing Android/iOS app'),
    ('package', 'Package', 'Shareable Dart/Flutter code'),
    ('package_ffi', 'Package FFI', 'Dart package with dart:ffi'),
    ('plugin', 'Plugin', 'Platform plugin with method channels'),
    ('plugin_ffi', 'Plugin FFI', 'Platform plugin with dart:ffi'),
  ];

  static const _allPlatforms = [
    'android',
    'ios',
    'web',
    'windows',
    'linux',
    'macos',
  ];

  bool get _showPlatforms => _template == 'app' || _template == 'plugin';
  bool get _showEmpty => _template == 'app';

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _descController.dispose();
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
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Image.asset(
                      'assets/language_icons/flutter-original.png',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'New Flutter Project',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Project name
                _label('Project Name'),
                _textField(_nameController),
                const SizedBox(height: 14),

                // Org
                _label('Organization'),
                _textField(_orgController, hint: 'com.example'),
                const SizedBox(height: 14),

                // Description
                _label('Description'),
                _textField(_descController),
                const SizedBox(height: 18),

                // Template
                _label('Template'),
                const SizedBox(height: 8),
                ..._templates.map(
                  (t) => _TemplateOption(
                    value: t.$1,
                    label: t.$2,
                    description: t.$3,
                    selected: _template == t.$1,
                    onTap: () => setState(() => _template = t.$1),
                  ),
                ),
                const SizedBox(height: 18),

                // Platforms
                if (_showPlatforms) ...[
                  _label('Platforms'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allPlatforms.map((p) {
                      final selected = _selectedPlatforms.contains(p);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected
                              ? _selectedPlatforms.remove(p)
                              : _selectedPlatforms.add(p);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.blue.withValues(alpha: 0.2)
                                : AppColors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.blue
                                  : AppColors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.white
                                  : AppColors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                ],

                // Android language
                _label('Android Language'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _RadioChip(
                      label: 'Kotlin',
                      selected: _androidLanguage == 'kotlin',
                      onTap: () => setState(() => _androidLanguage = 'kotlin'),
                    ),
                    const SizedBox(width: 8),
                    _RadioChip(
                      label: 'Java',
                      selected: _androidLanguage == 'java',
                      onTap: () => setState(() => _androidLanguage = 'java'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Toggles
                _Toggle(
                  label: 'Run pub get after creation',
                  value: _runPub,
                  onChanged: (v) => setState(() => _runPub = v),
                ),
                if (_showEmpty)
                  _Toggle(
                    label: 'Empty template (minimal main.dart)',
                    value: _empty,
                    onChanged: (v) => setState(() => _empty = v),
                  ),

                const SizedBox(height: 24),

                // Actions
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
                          'template': _template,
                          'org': _orgController.text.trim(),
                          'description': _descController.text.trim(),
                          'platforms': _selectedPlatforms,
                          'androidLanguage': _androidLanguage,
                          'pub': _runPub,
                          'empty': _empty,
                        });
                      },
                      child: const Text('Create'),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _textField(TextEditingController controller, {String? hint}) =>
      TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.3)),
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
      );
}

// Reusable sub-widgets

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

class _RadioChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue.withValues(alpha: 0.2)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.6),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 8),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
