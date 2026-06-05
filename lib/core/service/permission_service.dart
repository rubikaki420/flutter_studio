import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAllPermissions() async {
    // Notification permission (Android 13+)
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }

    // Storage permission (Android 11+ / All files access)
    if (!await Permission.manageExternalStorage.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  static Future<bool> hasPermissions() async {
    final notification = await Permission.notification.status;
    final storage = await Permission.manageExternalStorage.status;

    return notification.isGranted && storage.isGranted;
  }

  static Future<void> openSettingsIfDenied() async {
    final storage = await Permission.manageExternalStorage.status;

    if (storage.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
}
