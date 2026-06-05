import 'package:flutter/material.dart';
import '../language/language.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';

class InstallDialog extends StatefulWidget {
  final LanguageInstaller installer;
  final VoidCallback onInstalled;

  const InstallDialog({
    super.key,
    required this.installer,
    required this.onInstalled,
  });

  @override
  State<InstallDialog> createState() => _InstallDialogState();
}

class _InstallDialogState extends State<InstallDialog> {
  final StringBuffer logs = StringBuffer();

  bool installing = false;
  bool finished = false;

  Future<void> startInstall() async {
    setState(() {
      installing = true;
      logs.clear();
    });

    try {
      await for (final output in widget.installer.install()) {
        if (!mounted) return;

        setState(() {
          logs.write(output);
        });
      }

      widget.onInstalled();

      setState(() {
        finished = true;
      });
    } catch (e) {
      setState(() {
        logs.write('\nERROR: $e\n');
      });
    } finally {
      setState(() {
        installing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Install Language Support"),
      content: SizedBox(
        width: 600,
        height: 350,
        child: Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.black,
          child: SingleChildScrollView(
            child: SelectableText(
              logs.toString(),
              style: const TextStyle(
                color: AppColors.greenAccent,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (!installing && !finished)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

        if (!installing && !finished)
          FilledButton(onPressed: startInstall, child: const Text('Install')),

        if (installing)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),

        if (finished)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
