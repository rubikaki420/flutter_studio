import 'terminal_bottom_item.dart';

class TerminalSessionController {
  final String id;
  final TerminalBottomItem terminalItem;

  TerminalSessionController({required this.id, required this.terminalItem});

  Future<void> execute(String command) async {
    await terminalItem.executeCommand(command);
  }

  Future<void> dispose() async {
    await terminalItem.dispose();
  }
}
