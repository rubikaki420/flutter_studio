import 'language.dart';

class LanguageRegistry {
  static final List<Language> _languages = [];

  /// Register a language plugin (no duplicates allowed)
  static void register(Language language) {
    final exists = _languages.any((l) => l.languageId == language.languageId);

    if (exists) return;

    _languages.add(language);
  }

  /// Get all registered languages (read-only)
  static List<Language> get all => List.unmodifiable(_languages);

  /// Find language by ID
  static Language? getById(String id) {
    try {
      return _languages.firstWhere((l) => l.languageId == id);
    } catch (_) {
      return null;
    }
  }

  /// Find language by file extension
  static Language? getByExtension(String extension) {
    try {
      return _languages.firstWhere((l) => l.extensions.contains(extension));
    } catch (_) {
      return null;
    }
  }

  /// Initialize all languages
  static Future<void> initializeAll(dynamic context) async {
    for (final language in _languages) {
      await language.initialize(context);
    }
  }

  /// Dispose all languages safely
  static Future<void> disposeAll() async {
    for (final language in _languages) {
      await language.dispose();
    }
  }

  /// Clear registry (useful for testing / hot reload)
  static void clear() {
    _languages.clear();
  }

  static final Map<String, String> extensionMap = {
    'c': 'c',
    'h': 'c',
    'cpp': 'cpp',
    'hpp': 'cpp',
    'cc': 'cpp',
    'hh': 'cpp',
    'dart': 'dart',
    'js': 'javascript',
    'mjs': 'javascript',
    'cjs': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'html': 'xml',
    'htm': 'xml',
    'css': 'css',
    'py': 'python',
    "java": "java",
    "kt": "kotlin",
  };

  static String fromExtension(String ext) {
    return extensionMap[ext.toLowerCase()] ?? 'plaintext';
  }
}
