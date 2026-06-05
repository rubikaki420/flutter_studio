import 'package:flutter_studio/LSP/lsp.dart';
import 'package:flutter_studio/core/language/language.dart';

class LanguageServerManager {
  LanguageServerManager._();

  static final Map<String, LspConfig> _instances = {};

  static Future<LspConfig?> acquire({
    required Language language,
    required String workspacePath,
  }) async {
    if (_instances.containsKey(workspacePath)) {
      return _instances[workspacePath];
    }

    try {
      final config = await LspStdioConfig.start(
        executable: language.executable,
        args: language.args,
        workspacePath: workspacePath,
        languageId: language.languageId,
      );
      _instances[workspacePath] = config;
      return config;
    } catch (e) {
      //debugPrint('LSP start failed for $workspacePath: $e');
      return null;
    }
  }

  static void release(String workspacePath) {
    final instance = _instances.remove(workspacePath);
    instance?.dispose();
  }

  static LspConfig? get(String workspacePath) {
    return _instances[workspacePath];
  }

  static bool isRunning(String workspacePath) {
    return _instances.containsKey(workspacePath);
  }
}