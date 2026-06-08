import 'dart:convert';
import 'dart:io';
import 'package:flutter_studio/core/language/language.dart';
import 'package:flutter_studio/core/termux_env.dart';

class HtmlLanguageInstaller implements LanguageInstaller {
  @override
  String get languageId => 'html';

  @override
  Future<bool> isInstalled() async {
    final isLspAvailable = await PreInstallChecker.isCommandAvailable(
      'vscode-html-language-server',
      'vscode-html-language-server',
    );
    final isPrettierAvailable = await PreInstallChecker.isCommandAvailable(
      'prettier',
      'prettier',
    );

    return isLspAvailable && isPrettierAvailable;
  }

  /// install node/npm
  Stream<String> _installNpm() async* {
    yield 'npm not found. Installing nodejs...\n';

    final process = await TermuxEnv.start('${PreInstallChecker.basePath}/apt', [
      'install',
      'nodejs',
      '-y',
    ], runInShell: true);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final code = await process.exitCode;
    if (code != 0) {
      throw Exception('Node/NPM install failed: $code');
    }

    yield '\n✓ Node/NPM installed successfully\n';
  }

  /// install html lsp
  Stream<String> _installHtmlLsp() async* {
    yield 'Installing HTML language server...\n';

    final process = await TermuxEnv.start('npm', [
      'install',
      '-g',
      'vscode-langservers-extracted',
    ], runInShell: true);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final code = await process.exitCode;
    if (code != 0) {
      throw Exception('HTML LSP install failed: $code');
    }

    yield '\n✓ HTML Language Server installed successfully\n';
  }

  /// install prettier
  Stream<String> _installPrettier() async* {
    yield 'Installing Prettier...\n';

    final process = await TermuxEnv.start('npm', [
      'install',
      '-g',
      'prettier',
    ], runInShell: true);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final code = await process.exitCode;
    if (code != 0) {
      throw Exception('Prettier install failed: $code');
    }

    yield '\n✓ Prettier installed successfully\n';
  }

  @override
  Stream<String> install() async* {
    // STEP 1: npm check & install
    final isNpmAvailable = await PreInstallChecker.isCommandAvailable(
      'npm',
      'npm',
    );
    if (!isNpmAvailable) {
      yield* _installNpm();
    } else {
      yield '✓ npm already available\n';
    }

    // STEP 2: LSP check & install
    final isLspAvailable = await PreInstallChecker.isCommandAvailable(
      'vscode-html-language-server',
      'vscode-html-language-server',
    );
    if (!isLspAvailable) {
      yield* _installHtmlLsp();
    } else {
      yield '✓ HTML LSP already installed\n';
    }

    // STEP 3: Prettier check & install
    final isPrettierAvailable = await PreInstallChecker.isCommandAvailable(
      'prettier',
      'prettier',
    );
    if (!isPrettierAvailable) {
      yield* _installPrettier();
    } else {
      yield '✓ Prettier already installed\n';
    }
  }

  @override
  Stream<String> uninstall() async* {
    yield 'Removing HTML tools...\n';

    final process = await TermuxEnv.start('npm', [
      'uninstall',
      '-g',
      'vscode-html-language-server',
    ], runInShell: true);

    yield* process.stdout.transform(utf8.decoder);
    yield* process.stderr.transform(utf8.decoder);

    final code = await process.exitCode;
    if (code != 0) {
      throw Exception('Uninstall failed: $code');
    }

    yield '\n✓ HTML tools removed successfully\n';
  }

  @override
  Future<String?> getVersion() async {
    try {
      final lsp = await TermuxEnv.run('vscode-html-language-server', [
        '--version',
      ]);
      final prettier = await TermuxEnv.run('prettier', ['--version']);

      return '''
HTML LSP: ${lsp.stdout.toString().trim()}
Prettier: ${prettier.stdout.toString().trim()}
''';
    } catch (_) {
      try {
        final lsp = await TermuxEnv.run(
          '${PreInstallChecker.basePath}/vscode-langservers-extracted',
          ['--version'],
        );
        final prettier = await TermuxEnv.run(
          '${PreInstallChecker.basePath}/prettier',
          ['--version'],
        );
        return '''
HTML LSP: ${lsp.stdout.toString().trim()}
Prettier: ${prettier.stdout.toString().trim()}
''';
      } catch (_) {
        return null;
      }
    }
  }
}
