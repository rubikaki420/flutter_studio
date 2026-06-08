import 'dart:io';

class TermuxEnv {
  TermuxEnv._();

  static const String prefix = '/data/data/com.vault.fide/files/usr';
  static const String basePath = '$prefix/bin';
  static const String home = '/data/data/com.vault.fide/files/home';
  static const String javaHome = '$prefix/lib/jvm/java-21-openjdk';
  static const String androidHome = '$prefix/opt/android-sdk';
  static const String flutterBin = '$prefix/opt/flutter/bin/flutter';
  static const String projectsDir = '/storage/emulated/0/AndroidIDEProjects';

  static const String path = '$basePath'
      ':$androidHome/cmdline-tools/bin'
      ':$androidHome/platform-tools'
      ':$androidHome/build-tools/36.1.0'
      ':$prefix/opt/flutter/bin'
      ':$androidHome/cmake/4.1.2/bin';

  static Map<String, String> get environment => {
        'PATH': path,
        'HOME': home,
        'PREFIX': prefix,
        'JAVA_HOME': javaHome,
        'ANDROID_HOME': androidHome,
        'TMPDIR': '$prefix/tmp',
        'TERM': 'xterm-256color',
        'COLORTERM': 'truecolor',
      };

  static Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = true,
  }) {
    return Process.start(
      executable,
      arguments,
      environment: environment,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );
  }

  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) {
    return Process.run(
      executable,
      arguments,
      environment: environment,
      workingDirectory: workingDirectory,
    );
  }
}
