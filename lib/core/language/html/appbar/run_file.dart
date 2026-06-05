import 'package:flutter/material.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import '../bottom/preview_file.dart';
import '../html_language.dart';

class RunFile extends AppbarActionItem {
  @override
  String get id => "editor.html.appbar.run_file";

  @override
  String get label => "Run";

  @override
  Widget? get icon => Image.asset("assets/action_icons/run.png");

  @override
  Future<void> execute(EditorContext context) async {
    final path = context.currentFilePath;
    if (path == null) return;

    final bottomRegistry = context.bottomRegistry;
    if (bottomRegistry != null) {
      final item = bottomRegistry.findItem('editor.html.bottom.preview');
      if (item is PreviewFile) {
        final htmlLanguage = context.language is HtmlLanguage
            ? context.language as HtmlLanguage
            : null;
        item.load(path, htmlLanguage);
      }
      bottomRegistry.selectItemById('editor.html.bottom.preview');
    }
  }

  @override
  bool canExecute(EditorContext context) {
    final path = context.currentFilePath;
    return path?.endsWith('.html') == true || path?.endsWith('.htm') == true;
  }
}
