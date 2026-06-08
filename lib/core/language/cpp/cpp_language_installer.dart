import 'dart:convert';
import 'dart:io';
import 'package:flutter_studio/core/language/language.dart';
import 'package:flutter_studio/core/termux_env.dart';

class CPPLanguageInstaller implements LanguageInstaller {
  @override
  String get languageId => 'cpp';

  @override
  Future<bool> isInstalled() async {
    // PreInstallChecker ব্যবহার করা হয়েছে
    return PreInstallChecker.isCommandAvailable('clang++', 'clang++');
  }

  @override
  Stream<String> install() async* {
    final process = await TermuxEnv.start('${PreInstallChecker.basePath}/apt', [
      'install',
      'clang',
      'libstdc++-dev',
      '-y',
    ]);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('C++ installation failed (exit code: $exitCode)');
    }

    yield '\n✓ C++ toolchain installed successfully\n';
  }

  @override
  Stream<String> uninstall() async* {
    final process = await TermuxEnv.start('${PreInstallChecker.basePath}/apt', [
      'remove',
      'clang',
      'libstdc++-dev',
      '-y',
    ]);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('C++ uninstall failed (exit code: $exitCode)');
    }

    yield '\n✓ C++ toolchain removed successfully\n';
  }

  @override
  Future<String?> getVersion() async {
    try {
      final result = await TermuxEnv.run('clang++', ['--version']);
      if (result.exitCode != 0) return null;
      return result.stdout.toString().trim();
    } catch (_) {
      return null;
    }
  }
}
