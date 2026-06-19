
import 'package:flutter/services.dart';
class ApkInstaller {
  static const MethodChannel _channel =
    MethodChannel('com.vault.fide/channel');

  static Future<void> installApk(String path) async {
    await _channel.invokeMethod('installApk', {
      'path': path,
    });
  }
}