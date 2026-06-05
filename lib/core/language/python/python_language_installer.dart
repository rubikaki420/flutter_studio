import 'dart:convert';
import 'dart:io';

import 'package:flutter_studio/core/language/language.dart';

class PythonLanguageInstaller implements LanguageInstaller {
  @override
  String get languageId => 'python';

  @override
  Future<bool> isInstalled() async {
    return PreInstallChecker.isCommandAvailable(
      'python',
      'python',
      customFallbackPath: '/data/data/com.vault.fide/files/usr/bin/python',
    );
  }

  @override
  Stream<String> install() async* {
    final process = await Process.start('${PreInstallChecker.basePath}/apt', [
      'install',
      'python',
      '-y',
    ]);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception('Python installation failed (exit code: $exitCode)');
    }

    yield '\n✓ Python installed successfully\n';

    // Install Python LSP
    final lspProcess = await Process.start('pip', [
      'install',
      'python-lsp-server',
    ]);

    yield* lspProcess.stdout.transform(utf8.decoder);
    yield* lspProcess.stderr.transform(utf8.decoder);

    await lspProcess.exitCode;

    yield '\n✓ Python LSP installed successfully\n';
  }

  @override
  Stream<String> uninstall() async* {
    final process = await Process.start('${PreInstallChecker.basePath}/apt', [
      'remove',
      'python',
      '-y',
    ]);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception('Python uninstall failed (exit code: $exitCode)');
    }

    yield '\n✓ Python removed successfully\n';
  }

  @override
  Future<String?> getVersion() async {
    try {
      final result = await Process.run('python', ['--version']);

      if (result.exitCode != 0) {
        return null;
      }

      return result.stdout.toString().trim().isNotEmpty
          ? result.stdout.toString().trim()
          : result.stderr.toString().trim();
    } catch (_) {
      return null;
    }
  }
}
