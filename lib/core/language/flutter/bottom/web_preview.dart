import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/flutter/flutter_language.dart';

class WebPreview implements BottomItem {
  InAppWebViewController? _controller;

  bool _hasLoaded = false;

  @override
  String get id => 'editor.flutter.bottom.preview';

  @override
  String get title => 'Preview';

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

  bool _isAppLaunched(EditorContext context) {
    final lang = context.language;
    return lang is FlutterLanguage && (lang.state?.isAppLaunched ?? false);
  }

  void _tryLoad(EditorContext context) {
    // debugPrint("Test LOG : TRY LOAD");

    final launched = _isAppLaunched(context);

    //  debugPrint("Test LOG :   - launched=$launched");
    // debugPrint("Test LOG :   - controller=${_controller != null}");
    //  debugPrint("Test LOG :   - hasLoaded=$_hasLoaded");

    if (!launched || _controller == null || _hasLoaded) {
      //  debugPrint("Test LOG : Not ready");
      return;
    }

    _hasLoaded = true;

    const url = "http://localhost:8080";

    // debugPrint("Test LOG : LOADING -> $url");

    _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Future<void> prepare(EditorContext context) async {
    // debugPrint("Test LOG : prepare() called");

    final lang = context.language;

    if (lang is FlutterLanguage) {
      lang.state?.addListener(() {
        // debugPrint("Test LOG : state changed -> isAppLaunched=${lang.state?.isAppLaunched}");
        _tryLoad(context);
      });
    }
  }

  @override
  Widget build(BuildContext context, EditorContext editorContext) {
    // debugPrint("Test LOG : build()");

    final launched = _isAppLaunched(editorContext);

    if (!launched && !_hasLoaded) {
      return Container(
        color: const Color(0xFF0D1117),
        child: const Center(
          child: Text(
            "Run your file to see magic",
            style: TextStyle(color: Color(0xFF6C7086)),
          ),
        ),
      );
    }

    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        cacheEnabled: true,
        useHybridComposition: true,
      ),

      onWebViewCreated: (controller) {
        _controller = controller;
        //debugPrint("Test LOG : WebView CREATED");

        //  important: defer to next frame (avoids race condition)
        Future.microtask(() => _tryLoad(editorContext));
      },

      onLoadStart: (controller, url) {
        //debugPrint("⬇Test LOG : LOAD START -> $url");
      },

      onLoadStop: (controller, url) {
        // debugPrint("Test LOG : LOAD STOP -> $url");
      },

      // onLoadError: (controller, url, code, message) {
      // //  debugPrint("Test LOG : LOAD ERROR -> $message");
      // },
      onReceivedError: (controller, request, error) {
        // debugPrint("Test LOG : RECEIVED ERROR -> ${error.description}");
      },

      onConsoleMessage: (controller, msg) {
        //  debugPrint("Test LOG : JS -> ${msg.message}");
      },
    );
  }

  @override
  Future<void> onSelected(EditorContext context) async {
    //   debugPrint("Test LOG : selected");
  }

  @override
  Future<void> onUnselected(EditorContext context) async {
    //  debugPrint("Test LOG : unselected");
  }

  @override
  Future<void> dispose() async {
    // debugPrint("Test LOG : dispose");
    _controller = null;
    _hasLoaded = false;
  }
}
