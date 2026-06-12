/*
* Written by @Annon4You
*/

import 'dart:io';

class TermuxEnv {
  TermuxEnv._();

  static const String prefix = '/data/data/com.vault.fide/files/usr';
  static const String binPath = '$prefix/bin';
  static const String home = '/data/data/com.vault.fide/files/home';

  static Map<String, String> get _baseEnv => {
    'PATH': binPath,
    'HOME': home,
    'PREFIX': prefix,
    'LD_LIBRARY_PATH': '$prefix/lib',
    'TERM': 'xterm-256color',
    'COLORTERM': 'truecolor',
    'TMPDIR': '$prefix/tmp',
  };

  static String? _discoveredPath;

  static Future<String> _getDiscoveredPath() async {
    if (_discoveredPath != null) return _discoveredPath!;

    final result = await Process.run('$binPath/bash', [
      '-c',
      _profileWrapper('echo \$PATH'),
    ], environment: _baseEnv);

    final discovered = result.stdout.toString().trim();
    _discoveredPath = discovered.isNotEmpty ? discovered : binPath;
    return _discoveredPath!;
  }

  /// Starts a process.
  ///
  /// [extraPaths] — caller passes any additional paths they resolved
  /// (e.g. flutter bin dir from `which flutter`). These are prepended
  /// to the discovered PATH so they take priority.
  ///
  /// Example (Flutter):
  /// ```dart
  /// final flutterPath = await PreInstallChecker.resolveCommandPath('flutter');
  /// final flutterDir  = flutterPath != null
  ///     ? File(flutterPath).parent.path
  ///     : null;
  ///
  /// await TermuxEnv.start(
  ///   flutterPath!,
  ///   ['run'],
  ///   extraPaths: [if (flutterDir != null) flutterDir],
  /// );
  /// ```
  static Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    List<String> extraPaths = const [],
  }) async {
    final env = await _buildEnv(extraPaths);
    return Process.start(
      '$binPath/bash',
      ['-l', executable, ...arguments],
      environment: env,
      workingDirectory: workingDirectory,
    );
  }
  /// Starts a process directly without using bash.
  ///
  /// Unlike `start()`, this method does not wrap the command in a shell.
  /// It executes the binary directly using `Process.start()`.
  ///
  /// Use this for native executables like Dart ELF binaries
  /// to avoid shell-related issues (e.g. "cannot execute binary file").
  /// to get more information see `start()`
  static Future<Process> startPlain(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    List<String> extraPaths = const [],
  }) async {
    final env = await _buildEnv(extraPaths);
  
    return Process.start(
      executable,
      arguments,
      environment: env,
      workingDirectory: workingDirectory,
    );
  }

  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    List<String> extraPaths = const [],
  }) async {
    final env = await _buildEnv(extraPaths);
    return Process.run(
      '$binPath/bash',
      ['-l', executable, ...arguments],
      environment: env,
      workingDirectory: workingDirectory,
    );
  }

  static Future<Map<String, String>> _buildEnv(List<String> extraPaths) async {
    final discovered = await _getDiscoveredPath();

    final mergedPath = [
      ...extraPaths, // caller-supplied paths first (highest priority)
      discovered, // bash-discovered PATH (includes all installed tools)
    ].join(':');

    return {..._baseEnv, 'PATH': mergedPath};
  }

  static String _profileWrapper(String command) =>
      '''
    export HOME="$home"
    export PREFIX="$prefix"
    set +e
    command_not_found_handle() { return 127; }
    [ -f $prefix/etc/bash.bashrc ] && source $prefix/etc/bash.bashrc 2>/dev/null
    [ -f $home/.bashrc ]           && source $home/.bashrc           2>/dev/null
    $command
  ''';
  static Future<Map<String, String>> environment({
    List<String> extraPaths = const [],
  }) async {
    return _buildEnv(extraPaths);
  }
}
