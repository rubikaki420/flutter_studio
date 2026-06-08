import 'dart:convert';
import 'dart:io';

import 'package:flutter_studio/core/language/language.dart';

class FlutterLanguageInstaller implements LanguageInstaller {
  @override
  String get languageId => 'flutter';

  @override
  Future<bool> isInstalled() async {
    return PreInstallChecker.isCommandAvailable('/data/data/com.vault.fide/files/usr/bin/flutter', '/data/data/com.vault.fide/files/usr/bin/flutter');
  }

  @override
  Stream<String> install() async* {
    // 1. Install Flutter SDK
    final flutterProcess = await Process.start(
      '${PreInstallChecker.basePath}/apt',
      ['install', 'flutter', '-y'],
    );

    yield* flutterProcess.stdout.transform(utf8.decoder);
    yield* flutterProcess.stderr.transform(utf8.decoder);

    final flutterExit = await flutterProcess.exitCode;

    if (flutterExit != 0) {
      throw Exception('Flutter installation failed');
    }

    yield '\n✓ Flutter SDK installed\n';
  }

  @override
  Stream<String> uninstall() async* {
    final process = await Process.start('${PreInstallChecker.basePath}/apt', [
      'remove',
      'flutter',
      '-y',
    ]);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    await process.exitCode;

    yield '\n✓ Flutter removed\n';
  }

  @override
  Future<String?> getVersion() async {
    try {
      final result = await Process.run('/data/data/com.vault.fide/files/usr/bin/flutter', ['--version']);

      if (result.exitCode != 0) {
        return null;
      }

      return result.stdout.toString().split('\n').first.trim();
    } catch (_) {
      return null;
    }
  }
}
