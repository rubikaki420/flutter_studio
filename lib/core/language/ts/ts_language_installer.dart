import 'dart:convert';
import 'dart:io';

import 'package:flutter_studio/core/language/language.dart';

class TsLanguageInstaller implements LanguageInstaller {
  @override
  String get languageId => 'typescript';

  @override
  Future<bool> isInstalled() async {
    return PreInstallChecker.isCommandAvailable('node', 'node');
  }

  @override
  Stream<String> install() async* {
    final aptProcess = await Process.start(
      '${PreInstallChecker.basePath}/apt',
      ['install', 'nodejs', '-y'],
    );

    yield* aptProcess.stdout.transform(utf8.decoder);
    yield* aptProcess.stderr.transform(utf8.decoder);

    final exitCode = await aptProcess.exitCode;

    if (exitCode != 0) {
      throw Exception('Node.js installation failed');
    }

    yield '\n✓ Node.js installed\n';

    final npmProcess = await Process.start('npm', [
      'install',
      '-g',
      'typescript',
      'typescript-language-server',
      'ts-node',
      'prettier',
    ]);

    yield* npmProcess.stdout.transform(utf8.decoder);
    yield* npmProcess.stderr.transform(utf8.decoder);

    final npmExit = await npmProcess.exitCode;

    if (npmExit != 0) {
      throw Exception('TypeScript tools installation failed');
    }

    yield '\n✓ TypeScript toolchain installed\n';
    yield '✓ typescript\n';
    yield '✓ typescript-language-server\n';
    yield '✓ ts-node\n';
    yield '✓ prettier\n';
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
