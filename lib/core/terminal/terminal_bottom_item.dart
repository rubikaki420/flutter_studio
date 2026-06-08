import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_item.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter/rendering.dart';

/// Callback map: pattern string → onMatch callback
typedef PatternCallback = void Function(String matchedPattern);

class TerminalBottomItem extends ChangeNotifier implements BottomItem {
  final String _id;
  String _title;

  TerminalBottomItem({
    String? id,
    String? title,
    this.initialCommand,
    this.commandDelay = const Duration(milliseconds: 800),
  }) : _id =
           id ??
           'editor.bottom.terminal.${DateTime.now().millisecondsSinceEpoch}',
       _title = title ?? 'Terminal';

  MethodChannel? _channel;

  String? initialCommand;
  final Duration commandDelay;

  final Map<String, PatternCallback?> _patternCallbacks = {};
  final List<String> _pendingCommands = [];

  @override
  String get id => _id;

  @override
  String get title => _title;

  set title(String value) {
    if (_title == value) return;
    _title = value;
    notifyListeners();
  }

  @override
  Widget? get icon => const Icon(Icons.terminal);

  @override
  bool get visible => true;

  @override
  bool get enabled => true;

  @override
  int get order => 1;

  @override
  bool get keepAlive => true;

  @override
  Future<void> prepare(EditorContext context) async {}

  Future<void> watchPattern(String pattern, {PatternCallback? onMatch}) async {
    _patternCallbacks[pattern] = onMatch;

    if (_channel == null) return;
    try {
      await _channel!.invokeMethod('watchPattern', {'pattern': pattern});
    } on PlatformException catch (e) {
      debugPrint('Terminal: watchPattern failed — ${e.message}');
    }
  }

  Future<void> removePattern(String pattern) async {
    _patternCallbacks.remove(pattern);

    if (_channel == null) return;
    try {
      await _channel!.invokeMethod('removePattern', {'pattern': pattern});
    } on PlatformException catch (e) {
      debugPrint('Terminal: removePattern failed — ${e.message}');
    }
  }

  Future<void> clearPatterns() async {
    _patternCallbacks.clear();

    if (_channel == null) return;
    try {
      await _channel!.invokeMethod('clearPatterns');
    } on PlatformException catch (e) {
      debugPrint('Terminal: clearPatterns failed — ${e.message}');
    }
  }

  Future<void> resetPattern(String pattern) async {
    if (_channel == null) return;
    try {
      await _channel!.invokeMethod('resetPattern', {'pattern': pattern});
    } on PlatformException catch (e) {
      debugPrint('Terminal: resetPattern failed — ${e.message}');
    }
  }

  Future<void> executeCommand(String command) async {
    if (_channel == null) {
      _pendingCommands.add(command);
      return;
    }
    try {
      await _channel!.invokeMethod('sendCommand', {'command': command});
    } on PlatformException catch (e) {
      debugPrint('Terminal: sendCommand failed — ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context, EditorContext editorContext) {
    const String viewType = 'com.vault.fide/terminal_view';

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: const <String, dynamic>{},
      creationParamsCodec: const StandardMessageCodec(),
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      onPlatformViewCreated: (int id) {
        _channel = MethodChannel('com.vault.fide/terminal_control_$id');

        _channel!.setMethodCallHandler((MethodCall call) async {
          switch (call.method) {
            case 'onTerminalTextMatched':
              final text = call.arguments['matchedText'] as String?;
              if (text != null) _handleMatchedText(text);
              break;
            case 'onSessionFinished':
              onSessionFinished?.call();
              break;
            default:
              debugPrint('Terminal: unknown method — ${call.method}');
          }
        });

        for (final pattern in _patternCallbacks.keys) {
          _channel!.invokeMethod('watchPattern', {'pattern': pattern});
        }

        // Flush any commands queued before channel was ready
        for (final cmd in _pendingCommands) {
          _channel!.invokeMethod('sendCommand', {'command': cmd});
        }
        _pendingCommands.clear();

        // Auto-run command
        if (initialCommand != null) {
          Future.delayed(commandDelay, () => executeCommand(initialCommand!));
        }
      },
    );
  }

  void _handleMatchedText(String matchedPattern) {
    onTextMatched?.call(matchedPattern);

    final callback = _patternCallbacks[matchedPattern];
    callback?.call(matchedPattern);
  }

  void Function(String matched)? onTextMatched;

  void Function()? onSessionFinished;

  @override
  Future<void> onSelected(EditorContext context) async {}

  @override
  Future<void> onUnselected(EditorContext context) async {}

  @override
  Future<void> dispose() async {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    _patternCallbacks.clear();
    onTextMatched = null;
    onSessionFinished = null;
    super.dispose();
  }
}
