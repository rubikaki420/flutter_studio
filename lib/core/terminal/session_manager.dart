import 'package:flutter_studio/core/bottom_bar/bottom_registry.dart';
import 'terminal_bottom_item.dart';
import 'session_controller.dart';

class TerminalSessionManager {
  final BottomRegistry _bottomRegistry;
  final List<TerminalSessionController> _sessions = [];

  int _terminalCounter = 0;

  TerminalSessionManager(this._bottomRegistry);
  /// (Read-only)
  List<TerminalSessionController> get sessions => List.unmodifiable(_sessions);

  TerminalSessionController? findSessionById(String id) {
    try {
      return _sessions.firstWhere((session) => session.id == id);
    } catch (_) {
      return null;
    }
  }

  TerminalSessionController createSession({
    String? title,
    String? initialCommand,
    String? sessionId,
  }) {
    final finalSessionId =
        sessionId ?? 'editor.terminal.${DateTime.now().millisecondsSinceEpoch}';

    return _createNewSession(finalSessionId, title, initialCommand);
  }

  Future<void> executeInSession(String sessionId, String command) async {
    final session = findSessionById(sessionId);

    if (session == null) {
      throw Exception('Session not found: $sessionId');
    }

    await session.execute(command);
  }

  TerminalSessionController _createNewSession(
    String id,
    String? title,
    String? initialCommand,
  ) {
    _terminalCounter++;
    final terminalItem = TerminalBottomItem(
      id: id,
      title: title ?? 'Terminal ${_terminalCounter - 1}',
      initialCommand: initialCommand,
    );

    final controller = TerminalSessionController(
      id: id,
      terminalItem: terminalItem,
    );

    _sessions.add(controller);

    _bottomRegistry.registerItem(terminalItem);
    _bottomRegistry.selectItemById(id);

    return controller;
  }

  void removeSession(TerminalSessionController controller) {
    _sessions.remove(controller);
    _bottomRegistry.unregisterItem(controller.terminalItem);
    controller.dispose();
  }

  void dispose() {
    for (final session in _sessions) {
      session.dispose();
    }
    _sessions.clear();
  }
}
