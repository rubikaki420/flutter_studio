import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel("com.vault.fide/channel");

  static Future<String?> openTermuxActivity() async {
    try {
      final result = await _channel.invokeMethod("openTermuxActivity");
      return result;
    } catch (e) {
      // print("Error opening TermuxActivity: $e");
      return null;
    }
  }
}
