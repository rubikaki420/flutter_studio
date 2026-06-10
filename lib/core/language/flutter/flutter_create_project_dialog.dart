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
  final _pkgController = TextEditingController(text: 'com.example.myapp');

  @override
  void dispose() {
    _nameController.dispose();
    _pkgController.dispose();
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

                _label('App Name'),
                _textField(_nameController),
                const SizedBox(height: 14),

                _label('Package Name'),
                _textField(_pkgController, hint: 'com.example.myapp'),
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
                        final pkg = _pkgController.text.trim();
                        if (name.isEmpty || pkg.isEmpty) return;
                        Navigator.of(context).pop({
                          'name': name,
                          'pkg': pkg,
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
