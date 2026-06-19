import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/service/apk_installer.dart';
import 'package:flutter_studio/core/language/flutter/flutter_language.dart';
import 'package:flutter_studio/core/terminal/terminal_bottom_item.dart';

class BuildProject extends AppbarActionItem {
  static const String _buildSuccessPattern = 'Built build';
  static const String _aabSuccessPattern = 'appbundle written';
  static const String _flutterErrorPattern = 'No command flutter found';
  static const String _buildErrorPattern = 'BUILD FAILED';
  @override
  Widget? buildActionView(EditorContext context) => null;

  @override
  bool canExecute(EditorContext context) {
    final lang = context.language as FlutterLanguage?;
    if (lang == null) return false;

    final workspace = context.workspaceDirectory;
    if (workspace == null) return false;

    final pubspec = File('$workspace/pubspec.yaml');
    final mainFile = File('$workspace/lib/main.dart');

    return pubspec.existsSync() && mainFile.existsSync();
  }

  @override
  bool get enabled => true;

  @override
  String get id => 'editor.flutter.appbar.build_project';

  @override
  String get label => 'Build';

  @override
  int get order => 5;

  @override
  Widget? get icon => Image.asset('assets/action_icons/build.png');

  @override
  String? get subtitle => 'Build Android Project';

  @override
  bool get visible => true;

  @override
  bool get requiresUIThread => true;

  @override
  Future<void> execute(EditorContext context) async {
    final lang = context.language as FlutterLanguage?;
    final sessionManager = lang?.sessionManager;

    if (lang == null || sessionManager == null) {
      context.showMessage(message: 'Terminal not initialized');
      return;
    }

    final ctx = context.context;
    if (ctx == null) {
      context.showMessage(message: 'No UI context available');
      return;
    }

    final config = await _showBuildDialog(ctx);
    if (config == null) return;

    final workspace = context.workspaceDirectory!;
    final terminalId = FlutterLanguage.buildTerminalId;

    final command = _buildCommand(config);

    lang.state?.setAppRunning(true);

    final terminal = context.bottomRegistry?.findItem(FlutterLanguage.buildTerminalId);

    if (terminal is TerminalBottomItem) {
      await terminal.watchPattern(
        _buildSuccessPattern,
        onMatch: (_) {
          lang.state?.setAppRunning(false);
          context.actionsRegistry?.refresh();
          context.showMessage(message: 'Build completed successfully');
          
          final outputDir = Directory('$workspace/build/app/outputs/flutter-apk');
          final apkRegex = RegExp(r'app.*\.apk$');
          
          if (outputDir.existsSync()) {
            final apkFile = outputDir
                .listSync()
                .whereType<File>()
                .where((f) => apkRegex.hasMatch(f.path.split('/').last))
                .toList()
              ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
            
            if (apkFile.isNotEmpty) {
              ApkInstaller.installApk(apkFile.first.path);
            }
          }
        },
      );

      await terminal.watchPattern(
        _aabSuccessPattern,
        onMatch: (_) {
          lang.state?.setAppRunning(false);
          context.actionsRegistry?.refresh();
          context.showMessage(message: 'AAB build completed successfully');
        },
      );

      await terminal.watchPattern(
        _flutterErrorPattern,
        onMatch: (_) {
          lang.state?.setAppRunning(false);
          context.actionsRegistry?.refresh();
          context.showMessage(message: 'Flutter not found');
        },
      );

      await terminal.watchPattern(
        _buildErrorPattern,
        onMatch: (_) {
          lang.state?.setAppRunning(false);
          context.actionsRegistry?.refresh();
          context.showMessage(message: 'Build failed');
        },
      );
    }

    await sessionManager.executeInSession(
      FlutterLanguage.buildTerminalId,
      'cd $workspace && clear && $command',
      //'echo "Built build/app/outputs/flutter-apk/app-debug.apk"'
    );

    context.bottomRegistry?.selectItemById(terminalId);
    context.actionsRegistry?.refresh();
  }

  Future<_BuildConfig?> _showBuildDialog(BuildContext context) {
    return showDialog<_BuildConfig>(
      context: context,
      builder: (ctx) {
        _BuildType? type;
        final Set<_Abi> abis = {};

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Android Build Options'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Build Type"),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('APK Debug'),
                          selected: type == _BuildType.apkDebug,
                          onSelected: (_) =>
                              setState(() => type = _BuildType.apkDebug),
                        ),
                        ChoiceChip(
                          label: const Text('APK Release'),
                          selected: type == _BuildType.apkRelease,
                          onSelected: (_) =>
                              setState(() => type = _BuildType.apkRelease),
                        ),
                        ChoiceChip(
                          label: const Text('AAB (Play Store)'),
                          selected: type == _BuildType.aabRelease,
                          onSelected: (_) =>
                              setState(() => type = _BuildType.aabRelease),
                        ),
                        ChoiceChip(
                          label: const Text('Split APK'),
                          selected: type == _BuildType.splitAbi,
                          onSelected: (_) =>
                              setState(() => type = _BuildType.splitAbi),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Text("Architecture (ABI)"),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('arm64-v8a (aarch64)'),
                          selected: abis.contains(_Abi.arm64),
                          onSelected: (v) => setState(() {
                            v ? abis.add(_Abi.arm64) : abis.remove(_Abi.arm64);
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('armeabi-v7a'),
                          selected: abis.contains(_Abi.armv7),
                          onSelected: (v) => setState(() {
                            v ? abis.add(_Abi.armv7) : abis.remove(_Abi.armv7);
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('x86_64'),
                          selected: abis.contains(_Abi.x86_64),
                          onSelected: (v) => setState(() {
                            v
                                ? abis.add(_Abi.x86_64)
                                : abis.remove(_Abi.x86_64);
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: type == null
                      ? null
                      : () => Navigator.pop(ctx, _BuildConfig(type!, abis)),
                  child: const Text('Build'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _buildCommand(_BuildConfig config) {
    switch (config.type) {
      case _BuildType.apkDebug:
        return 'flutter build apk --debug';

      case _BuildType.apkRelease:
        return _buildAbiCommand(config, release: true);

      case _BuildType.aabRelease:
        return 'flutter build appbundle --release';

      case _BuildType.splitAbi:
        return 'flutter build apk --split-per-abi';
    }
  }

  String _buildAbiCommand(_BuildConfig config, {required bool release}) {
    final targets = <String>[];

    if (config.abis.contains(_Abi.arm64)) {
      targets.add('android-arm64');
    }
    if (config.abis.contains(_Abi.armv7)) {
      targets.add('android-arm');
    }
    if (config.abis.contains(_Abi.x86_64)) {
      targets.add('android-x64');
    }

    if (targets.isEmpty) {
      return release ? 'flutter build apk --release' : 'flutter build apk';
    }

    return 'flutter build apk --release --target-platform ${targets.join(',')}';
  }

  @override
  Future<void> dispose() async {}
}

class _BuildConfig {
  final _BuildType type;
  final Set<_Abi> abis;

  _BuildConfig(this.type, this.abis);
}

enum _BuildType { apkDebug, apkRelease, aabRelease, splitAbi }

enum _Abi {
  arm64, // aarch64
  armv7,
  x86_64,
}
