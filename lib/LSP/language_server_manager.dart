import 'package:flutter_studio/LSP/lsp.dart';
import 'package:flutter_studio/core/language/language.dart';

class LanguageServerManager {
  LanguageServerManager._();

  static final Map<String, LspConfig> _instances = {};

  static String _makeKey(String languageId, String workspacePath) {
    return '$languageId:$workspacePath';
  }

  static Future<LspConfig?> acquire({
    required Language language,
    required String workspacePath,
  }) async {
    final key = _makeKey(language.languageId, workspacePath);
    if (_instances.containsKey(key)) {
      return _instances[key];
    }

    try {
      final config = await LspStdioConfig.start(
        executable: language.executable,
        args: language.args,
        workspacePath: workspacePath,
        languageId: language.languageId,
      );
      _instances[key] = config;
      return config;
    } catch (e) {
      //debugPrint('LSP start failed for $workspacePath: $e');
      return null;
    }
  }

  static void release(String languageId, String workspacePath) {
    final key = _makeKey(languageId, workspacePath);
    final instance = _instances.remove(key);
    instance?.dispose();
  }

  static void releaseAll(String workspacePath) {
    final keysToRemove = _instances.keys
        .where((key) => key.endsWith(':$workspacePath'))
        .toList();

    for (final key in keysToRemove) {
      final instance = _instances.remove(key);
      instance?.dispose();
    }
  }

  static LspConfig? get(String languageId, String workspacePath) {
    return _instances[_makeKey(languageId, workspacePath)];
  }

  static bool isRunning(String languageId, String workspacePath) {
    return _instances.containsKey(_makeKey(languageId, workspacePath));
  }
}