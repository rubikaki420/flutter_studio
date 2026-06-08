import 'package:path/path.dart' as p;
import 'package:re_highlight/languages/all.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:flutter_studio/core/language/language_registry.dart';
import 'package:flutter_studio/core/language/language.dart';
import 'package:flutter_studio/code_forge.dart';

class EditorTabItem {
  final String filePath;
  final String fileName;
  final String workspacePath;

  final CodeForgeController codeForgeController;
  final UndoRedoController undoRedoController;

  const EditorTabItem({
    required this.filePath,
    required this.fileName,
    required this.codeForgeController,
    required this.undoRedoController,
    required this.workspacePath,
  });

  String get extension =>
      p.extension(filePath).replaceFirst(".", "").toLowerCase();

  /// extension → languageId (like : 'dart', 'c', 'xml')
  String get languageId => LanguageRegistry.fromExtension(extension);
  Language? get language =>
    LanguageRegistry.getByExtension(extension);
  Mode? get mode => builtinAllLanguages[languageId];
}
