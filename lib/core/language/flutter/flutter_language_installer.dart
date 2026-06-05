import 'dart:convert';
import 'dart:io';

import 'package:flutter_studio/core/language/language.dart';

class FlutterLanguageInstaller implements LanguageInstaller {
  @override
  String get languageId => 'flutter';

  @override
  Future<bool> isInstalled() async {
    return PreInstallChecker.isCommandAvailable('flutter', 'flutter');
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

    // 2. Install Android SDK
    final androidProcess = await Process.start(
      '${PreInstallChecker.basePath}/apt',
      ['install', 'android-sdk', '-y'],
    );

    yield* androidProcess.stdout.transform(utf8.decoder);
    yield* androidProcess.stderr.transform(utf8.decoder);

    final androidExit = await androidProcess.exitCode;

    if (androidExit != 0) {
      throw Exception('Android SDK installation failed');
    }

    yield '\n✓ Android SDK installed\n';

    // 3. Flutter doctor
    final doctor = await Process.start('flutter', ['doctor']);

    yield '\nRunning flutter doctor...\n';

    yield* doctor.stdout.transform(utf8.decoder);
    yield* doctor.stderr.transform(utf8.decoder);

    await doctor.exitCode;

    yield '\n✓ Flutter environment ready\n';
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
      final result = await Process.run('flutter', ['--version']);

      if (result.exitCode != 0) {
        return null;
      }

      return result.stdout.toString().split('\n').first.trim();
    } catch (_) {
      return null;
    }
  }
}
