import 'dart:convert';
import 'dart:io';
import 'package:flutter_studio/core/language/language.dart';

class DartLanguageInstaller implements LanguageInstaller {
  @override
  String get languageId => 'dart';

  @override
  Future<bool> isInstalled() async {
    return PreInstallChecker.isCommandAvailable(
      'dart',
      'dart',
      customFallbackPath:
          '/data/data/com.vault.fide/files/usr/opt/flutter/bin/dart',
    );
  }

  @override
  Stream<String> install() async* {
    final process = await Process.start('${PreInstallChecker.basePath}/apt', [
      'install',
      'dart',
      '-y',
    ]);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Dart installation failed (exit code: $exitCode)');
    }

    yield '\n✓ Dart toolchain installed successfully\n';
  }

  @override
  Stream<String> uninstall() async* {
    final process = await Process.start('${PreInstallChecker.basePath}/apt', [
      'remove',
      'dart',
      '-y',
    ]);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Dart uninstall failed (exit code: $exitCode)');
    }

    yield '\n✓ Dart toolchain removed successfully\n';
  }

  @override
  Future<String?> getVersion() async {
    try {
      final result = await Process.run('dart', ['--version']);
      if (result.exitCode != 0) return null;
      return result.stdout.toString().trim();
    } catch (_) {
      return null;
    }
  }
}
