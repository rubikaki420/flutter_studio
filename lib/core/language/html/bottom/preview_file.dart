// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_studio/core/bottom_bar/bottom_item.dart';
// import 'package:flutter_studio/core/editor_context.dart';
// import 'package:flutter_studio/core/language/html/html_language.dart';
// import 'package:path/path.dart' as p;

// class PreviewFile extends ChangeNotifier implements BottomItem {
// InAppWebViewController? _controller;
// String? _currentPath;

// @override
// String get id => 'editor.html.bottom.preview';

// @override
// String get title => 'HTML Preview';

// @override
// Widget? get icon => const Icon(Icons.remove_red_eye_outlined);

// @override
// bool get visible => true;

// @override
// bool get enabled => true;

// @override
// int get order => 0;

// @override
// bool get keepAlive => true;

// @override
// Future<void> prepare(EditorContext context) async {}

// void load(String path, HtmlLanguage? language) {
// _currentPath = path;
// if (_controller != null) {
// _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(_getFileUrl(path, language))));
// } else {
// notifyListeners();
// }
// }

// String _getFileUrl(String filePath, HtmlLanguage? language) {
// if (language?.httpServer?.isRunning == true) {
// final root = language!.httpServer!.rootPath;
// final relativePath = p.relative(filePath, from: root);
// return "http://localhost:${language.httpServer!.port}/$relativePath";
// }
// return "file://$filePath";
// }

// @override
// Widget build(BuildContext context, EditorContext editorContext) {
// return ListenableBuilder(
// listenable: this,
// builder: (context, _) {
// final path = _currentPath ?? editorContext.currentFilePath;
// final htmlLanguage = editorContext.language is HtmlLanguage
// ? editorContext.language as HtmlLanguage
// : null;

// final url = path != null ? _getFileUrl(path, htmlLanguage) : null;

// return InAppWebView(
// key: const ValueKey('html_preview_webview'),
// initialUrlRequest: url != null
// ? URLRequest(url: WebUri(url))
// : null,
// initialSettings: InAppWebViewSettings(
// allowFileAccessFromFileURLs: true,
// allowUniversalAccessFromFileURLs: true,
// javaScriptEnabled: true,
// ),
// onWebViewCreated: (controller) {
// _controller = controller;
// },
// );
// },
// );
// }

// @override
// Future<void> onSelected(EditorContext context) async {}

// @override
// Future<void> onUnselected(EditorContext context) async {}

// @override
// Future<void> dispose() async {
// _controller = null;
// super.dispose();
// }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_studio/core/bottom_bar/bottom_item.dart';
// import 'package:flutter_studio/core/editor_context.dart';
// import 'package:flutter_studio/core/language/html/html_language.dart';
// import 'package:path/path.dart' as p;

// class PreviewFile extends ChangeNotifier implements BottomItem {
// InAppWebViewController? _controller;
// String? _currentPath;

// @override
// String get id => 'editor.html.bottom.preview';

// @override
// String get title => 'HTML Preview';

// @override
// Widget? get icon =>  Icon(Icons.remove_red_eye_outlined);

// @override
// bool get visible => true;

// @override
// bool get enabled => true;

// @override
// int get order => 0;

// @override
// bool get keepAlive => true;

// @override
// Future<void> prepare(EditorContext context) async {}

// /// নতুন ফাইল লোড করার মেথড (path null হতে পারে সব ট্যাব ক্লোজ হলে)
// void load(String? path, HtmlLanguage? language) {
// _currentPath = path;

// if (path == null) {
// // ট্যাব খালি হলে কন্ট্রোলার এবং পাথ রিসেট করে ভিউ আপডেট করবে
// _controller = null;
// notifyListeners();
// return;
// }

// if (_controller != null) {
// final url = _getFileUrl(path, language);
// _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
// } else {
// notifyListeners();
// }
// }

// String _getFileUrl(String filePath, HtmlLanguage? language) {
// if (language?.httpServer?.isRunning == true) {
// final root = language!.httpServer!.rootPath;
// final relativePath = p.relative(filePath, from: root);
// return "http://localhost:${language.httpServer!.port}/$relativePath";
// }
// return "file://$filePath";
// }

// @override
// Widget build(BuildContext context, EditorContext editorContext) {
// return ListenableBuilder(
// listenable: this,
// builder: (context, _) {
// // প্রথমবার ওপেন বা রান বাটনে ক্লিক করলে সঠিক পাথ ট্র্যাক করা
// final path = _currentPath ?? editorContext.currentFilePath;

// final htmlLanguage = editorContext.language is HtmlLanguage
// ? editorContext.language as HtmlLanguage
// : null;

// final url = path != null ? _getFileUrl(path, htmlLanguage) : null;

// // যদি কোনো ফাইল ওপেন না থাকে (সব ট্যাব ক্লোজড)
// if (url == null) {
// return  Container(
// color: Color(0xFF0D1117),
// child: Center(
// child: Text(
// "No file to preview",
// style: TextStyle(color: Color(0xFF6C7086)),
// ),
// ),
// );
// }

// return InAppWebView(
// // 🔴 ফিক্স: ফিক্সড কী-এর বদলে ডায়নামিক 'url' কী ব্যবহার করা হয়েছে।
// // এর ফলে ট্যাব সম্পূর্ণ খালি হয়ে নতুন ফাইল রান করলে WebView ফ্রেশভাবে রিলোড হবে।
// key: ValueKey(url),
// initialUrlRequest: URLRequest(url: WebUri(url)),
// initialSettings: InAppWebViewSettings(
// allowFileAccessFromFileURLs: true,
// allowUniversalAccessFromFileURLs: true,
// javaScriptEnabled: true,
// ),
// onWebViewCreated: (controller) {
// _controller = controller;
// },
// onConsoleMessage: (controller, consoleMessage) {
// debugPrint("WebView Console: ${consoleMessage.message}");
// },
// );
// },
// );
// }

// @override
// Future<void> onSelected(EditorContext context) async {}

// @override
// Future<void> onUnselected(EditorContext context) async {}

// @override
// Future<void> dispose() async {
// _controller = null;
// _currentPath = null;
// super.dispose();
// }
// }
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/html/html_language.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_studio/core/utils/app_colors.dart';

class PreviewFile extends ChangeNotifier implements BottomItem {
  InAppWebViewController? _controller;
  String? _currentPath;

  @override
  String get id => 'editor.html.bottom.preview';

  @override
  String get title => 'HTML Preview';

  @override
  Widget? get icon => const Icon(Icons.remove_red_eye_outlined);

  @override
  bool get visible => true;

  @override
  bool get enabled => true;

  @override
  int get order => 0;

  @override
  bool get keepAlive => true;

  @override
  Future<void> prepare(EditorContext context) async {}

  /// Run button থেকে call হবে
  void load(String? path, HtmlLanguage? language) {
    _currentPath = path;

    // WebView rebuild করার জন্য
    notifyListeners();

    if (_controller != null && path != null) {
      final url = _getFileUrl(path, language);

      _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
  }

  String _getFileUrl(String filePath, HtmlLanguage? language) {
    if (language?.httpServer?.isRunning == true) {
      final root = language!.httpServer!.rootPath;
      final relativePath = p.relative(filePath, from: root);

      return "http://localhost:${language.httpServer!.port}/$relativePath";
    }

    return "file://$filePath";
  }

  @override
  Widget build(BuildContext context, EditorContext editorContext) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, _) {
        final path = _currentPath;

        final htmlLanguage = editorContext.language is HtmlLanguage
            ? editorContext.language as HtmlLanguage
            : null;

        final url = path != null ? _getFileUrl(path, htmlLanguage) : null;

        if (url == null) {
          return Container(
            color: AppColors.vscodeEditor,
            child: const Center(
              child: Text(
                "No file to preview",
                style: TextStyle(color: AppColors.overlay0),
              ),
            ),
          );
        }

        return InAppWebView(
          key: ValueKey(url),
          initialUrlRequest: URLRequest(url: WebUri(url)),
          initialSettings: InAppWebViewSettings(
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            javaScriptEnabled: true,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint("WebView Console: ${consoleMessage.message}");
          },
        );
      },
    );
  }

  @override
  Future<void> onSelected(EditorContext context) async {}

  @override
  Future<void> onUnselected(EditorContext context) async {}

  @override
  Future<void> dispose() async {
    _controller = null;
    _currentPath = null;
    super.dispose();
  }
}
