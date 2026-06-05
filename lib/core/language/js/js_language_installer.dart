import 'dart:convert';
import 'dart:io';

import 'package:flutter_studio/core/language/language.dart';

class JsLanguageInstaller implements LanguageInstaller {
  @override
  String get languageId => 'javascript';

  @override
  Future<bool> isInstalled() async {
    return PreInstallChecker.isCommandAvailable('node', 'node');
  }

  @override
  Stream<String> install() async* {
    final process = await Process.start('${PreInstallChecker.basePath}/apt', [
      'install',
      'nodejs',
      '-y',
    ]);

    yield* process.stdout.transform(utf8.decoder);

    yield* process.stderr.transform(utf8.decoder);

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception('Node.js installation failed');
    }

    yield '\n✓ Node.js installed\n';

    final npmPackages = await Process.start('npm', [
      'install',
      '-g',
      'typescript',
      'typescript-language-server',
      'prettier',
    ]);

    yield* npmPackages.stdout.transform(utf8.decoder);

    yield* npmPackages.stderr.transform(utf8.decoder);

    await npmPackages.exitCode;

    yield '\n✓ JavaScript tools installed\n';
    yield '✓ TypeScript Language Server\n';
    yield '✓ Prettier Formatter\n';
  }

  @override
  Stream<String> uninstall() async* {
    final process = await Process.start('${PreInstallChecker.basePath}/apt', [
      'remove',
      'nodejs',
      '-y',
    ]);

    yield* process.stdout.transform(utf8.decoder);

    yield* process.stderr.transform(utf8.decoder);

    await process.exitCode;

    yield '\n✓ Node.js removed\n';
  }

  @override
  Future<String?> getVersion() async {
    try {
      final result = await Process.run('node', ['--version']);

      if (result.exitCode != 0) {
        return null;
      }

      return result.stdout.toString().trim();
    } catch (_) {
      return null;
    }
  }
}
