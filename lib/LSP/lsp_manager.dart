// It is desperate but you can get idea for here
// import 'dart:async';

// import 'package:fide/core/models/language_model.dart';
// import 'package:fide/code_forge.dart';

// class LspManager {
  // static final Map<String, _LspEntry> _instances = {};

  // static String _key({
    // required String languageId,
    // required String workspacePath,
  // }) {
    // return '$languageId::$workspacePath';
  // }

  // static Future<LspConfig?> acquire({
    // required LanguageModel language,
    // required String workspacePath,
  // }) async {
    // final lsp = language.lsp;

    // if (lsp == null || lsp.executable == null) {
      // return null;
    // }

    // final key = _key(
      // languageId: language.languageId!,
      // workspacePath: workspacePath,
    // );

    // final existing = _instances[key];

    // if (existing != null) {
      // existing.refCount++;
      // return existing.config;
    // }

    // final config = await LspStdioConfig.start(
      // executable: lsp.executable!,
      // args: lsp.args ?? ['--stdio'],
      // workspacePath: workspacePath,
      // languageId: language.languageId!,
    // );

    // await config.initialize();

    // _instances[key] = _LspEntry(config: config, refCount: 1);

    // return config;
  // }

  // static Future<void> release({
    // required String languageId,
    // required String workspacePath,
  // }) async {
    // final key = _key(languageId: languageId, workspacePath: workspacePath);

    // final entry = _instances[key];

    // if (entry == null) return;

    // entry.refCount--;

    // if (entry.refCount <= 0) {
      // try {
        // await entry.config.shutdown();
        // await entry.config.exitServer();
      // } catch (_) {}

      // entry.config.dispose();

      // _instances.remove(key);
    // }
  // }

  // static Future<void> disposeAll() async {
    // for (final entry in _instances.values) {
      // try {
        // await entry.config.shutdown();
        // await entry.config.exitServer();
      // } catch (_) {}

      // entry.config.dispose();
    // }

    // _instances.clear();
  // }
// }

// class _LspEntry {
  // final LspConfig config;

  // int refCount;

  // _LspEntry({required this.config, required this.refCount});
// }
