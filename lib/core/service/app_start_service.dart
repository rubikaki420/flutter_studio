import 'package:shared_preferences/shared_preferences.dart';
import 'native_bridge.dart';

class AppStartService {
  static const String _termuxInitializedKey = "termux_initialized";

  static Future<void> handleFirstLaunchFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final isAlreadyInitialized = prefs.getBool(_termuxInitializedKey) ?? false;

    if (!isAlreadyInitialized) {
      // Open Termux (or run setup)
      await NativeBridge.openTermuxActivity();

      // Mark as initialized so we don't open it again
      await prefs.setBool(_termuxInitializedKey, true);
    }
  }

  static Future<bool> isTermuxReady() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termuxInitializedKey) ?? false;
  }
}
