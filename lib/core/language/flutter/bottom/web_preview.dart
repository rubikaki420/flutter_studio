import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/language/flutter/flutter_language.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';

class WebPreview implements BottomItem {
  InAppWebViewController? _controller;
  FlutterLanguageState? _state;

  bool _hasTriedLoad = false;
  bool _isLoading = false;

  final String _url = "http://localhost:8080";

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

  @override
  Future<void> prepare(EditorContext context) async {
    final lang = context.language;

    if (lang is FlutterLanguage) {
      _state = lang.state;

      _state?.addListener(() {
        _tryLoad();
      });
    }
  }

  Future<bool> _checkServer() async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(_url));
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _tryLoad() async {
    if (_controller == null) return;
    if (_state?.isAppLaunched != true) return;
    if (_isLoading) return;

    _isLoading = true;

    for (int i = 0; i < 20; i++) {
      final ok = await _checkServer();

      if (ok) {
        _hasTriedLoad = true;

        _controller!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(_url),
          ),
        );

        _isLoading = false;
        return;
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    _isLoading = false;
  }

  @override
  Widget build(BuildContext context, EditorContext editorContext) {
    final lang = editorContext.language;

    final isLaunched =
        lang is FlutterLanguage && (lang.state?.isAppLaunched ?? false);

    if (!isLaunched && !_hasTriedLoad) {
      return Container(
        color: AppColors.vscodeEditor,
        child: const Center(
          child: Text(
            "Run your file to see magic",
            style: TextStyle(color: AppColors.overlay0),
          ),
        ),
      );
    }

    return Stack(
      children: [
        InAppWebView(
          onWebViewCreated: (controller) {
            _controller = controller;
            _tryLoad();
          },
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            cacheEnabled: true,
          ),
        ),

      ],
    );
  }

  @override
  Future<void> onSelected(EditorContext context) async {}

  @override
  Future<void> onUnselected(EditorContext context) async {}

  @override
  Future<void> dispose() async {
    _controller = null;
    _state = null;
  }
}