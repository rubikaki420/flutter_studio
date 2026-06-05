import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';

class DartProjectCreationProgressDialog extends StatefulWidget {
  final List<String> args;
  final String projectPath;

  const DartProjectCreationProgressDialog({
    super.key,
    required this.args,
    required this.projectPath,
  });

  @override
  State<DartProjectCreationProgressDialog> createState() =>
      _DartProjectCreationProgressDialogState();
}

class _DartProjectCreationProgressDialogState
    extends State<DartProjectCreationProgressDialog> {
  final List<String> _lines = [];
  final ScrollController _scrollController = ScrollController();
  bool _done = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _runProcess();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runProcess() async {
    try {
      final process = await Process.start('dart', widget.args);

      process.stdout.transform(SystemEncoding().decoder).listen((data) {
        _appendLines(data);
      });

      process.stderr.transform(SystemEncoding().decoder).listen((data) {
        _appendLines(data);
      });

      final exitCode = await process.exitCode;

      if (!mounted) return;
      setState(() {
        _done = true;
        _success = exitCode == 0;
        _lines.add(
          _success
              ? '\n✓ Project created successfully.'
              : '\n✗ Failed with exit code $exitCode.',
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _done = true;
        _success = false;
        _lines.add('\n✗ Error: $e');
      });
    }
  }

  void _appendLines(String data) {
    if (!mounted) return;
    setState(() {
      _lines.addAll(data.split('\n'));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.vscodeBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!_done)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _success ? Icons.check_circle : Icons.error,
                      color: _success ? Colors.green : AppColors.orange,
                      size: 18,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    _done
                        ? (_success ? 'Project Created' : 'Creation Failed')
                        : 'Creating Project...',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Output terminal
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Text(
                    _lines.join('\n'),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (_done)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_success)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: AppColors.white),
                        ),
                      ),
                    if (_success)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Open Project'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
