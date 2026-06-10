import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/core/language/language_registry.dart';
import 'package:flutter_studio/core/language/c/c_language.dart';
import 'package:flutter_studio/core/language/cpp/cpp_language.dart';
import 'package:flutter_studio/core/language/dart/dart_language.dart';
import 'package:flutter_studio/core/language/html/html_language.dart';
import 'package:flutter_studio/core/language/flutter/flutter_language.dart';
import 'package:flutter_studio/core/language/js/js_language.dart';
import 'package:flutter_studio/core/language/python/python_language.dart';
import 'package:flutter_studio/core/language/ts/ts_language.dart';

import 'package:flutter_studio/core/activities/intro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  LanguageRegistry.register(CLanguage());
  LanguageRegistry.register(CPPLanguage());
  LanguageRegistry.register(DartLanguage());
  LanguageRegistry.register(FlutterLanguage());
  LanguageRegistry.register(HtmlLanguage());
  LanguageRegistry.register(JsLanguage());
  LanguageRegistry.register(PythonLanguage());
  LanguageRegistry.register(TsLanguage());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.vscodeSideBar,
        primaryColor: AppColors.blue,
      ),
     // home: const IntroGate(),
      home: const WhichDebugPage(),
    );
  }
}


// class WhichDebugPage extends StatefulWidget {
  // const WhichDebugPage({super.key});

  // @override
  // State<WhichDebugPage> createState() => _WhichDebugPageState();
// }

// class _WhichDebugPageState extends State<WhichDebugPage> {
  // final TextEditingController controller = TextEditingController();
  // String output = "";
  // bool loading = false;

  // static const String basePath =
      // '/data/data/com.vault.fide/files/usr/bin';

  // Future<void> runWhichTest(String command) async {
    // setState(() {
      // loading = true;
      // output = "";
    // });

    // try {
      // final whichPath = '$basePath/which';

      // // Step 1: check if which exists
      // final whichExists = File(whichPath).existsSync();

      // if (!whichExists) {
        // setState(() {
          // output = "❌ which binary NOT FOUND at: $whichPath";
          // loading = false;
        // });
        // return;
      // }

      // // Step 2: run which
      // final result = await Process.run(whichPath, [command]);

      // setState(() {
        // output = """
// 🔎 Command Tested: $command

// 📍 which path: $whichPath
// 📦 exitCode: ${result.exitCode}

// 📤 STDOUT:
// ${result.stdout}

// 📥 STDERR:
// ${result.stderr}
// """;
        // loading = false;
      // });
    // } catch (e) {
      // setState(() {
        // output = "❌ ERROR: $e";
        // loading = false;
      // });
    // }
  // }

  // Future<void> runPreInstallCheck(String command) async {
    // setState(() {
      // loading = true;
      // output = "";
    // });

    // try {
      // final result = await Process.run(
        // '$basePath/which',
        // [command],
      // );

      // setState(() {
        // output = """
// 🧪 PreInstallChecker-style test

// 🔎 command: $command
// 📦 exitCode: ${result.exitCode}

// stdout:
// ${result.stdout}

// stderr:
// ${result.stderr}
// """;
        // loading = false;
      // });
    // } catch (e) {
      // setState(() {
        // output = "❌ ERROR: $e";
        // loading = false;
      // });
    // }
  // }

  // @override
  // Widget build(BuildContext context) {
    // return Scaffold(
      // appBar: AppBar(
        // title: const Text("Which Debug Tool"),
      // ),
      // body: Padding(
        // padding: const EdgeInsets.all(16),
        // child: Column(
          // children: [
            // TextField(
              // controller: controller,
              // decoration: const InputDecoration(
                // labelText: "Enter command (e.g. flutter, ls, git)",
                // border: OutlineInputBorder(),
              // ),
            // ),
            // const SizedBox(height: 10),

            // Row(
              // children: [
                // Expanded(
                  // child: ElevatedButton(
                    // onPressed: loading
                        // ? null
                        // : () => runWhichTest(controller.text),
                    // child: const Text("Run raw which"),
                  // ),
                // ),
                // const SizedBox(width: 10),
                // Expanded(
                  // child: ElevatedButton(
                    // onPressed: loading
                        // ? null
                        // : () => runPreInstallCheck(controller.text),
                    // child: const Text("Run PreInstall check"),
                  // ),
                // ),
              // ],
            // ),

            // const SizedBox(height: 20),

            // if (loading) const CircularProgressIndicator(),

            // const SizedBox(height: 20),

            // Expanded(
              // child: SingleChildScrollView(
                // child: Container(
                  // width: double.infinity,
                  // padding: const EdgeInsets.all(12),
                  // color: Colors.black,
                  // child: Text(
                    // output,
                    // style: const TextStyle(
                      // color: Colors.greenAccent,
                    // //  fontFamily: "monospace",
                    // ),
                  // ),
                // ),
              // ),
            // ),
          // ],
        // ),
      // ),
    // );
  // }
// }

class WhichDebugPage extends StatefulWidget {
  const WhichDebugPage({super.key});

  @override
  State<WhichDebugPage> createState() => _WhichDebugPageState();
}

class _WhichDebugPageState extends State<WhichDebugPage> {
  final TextEditingController controller = TextEditingController();
  String output = "";
  bool loading = false;

  static const String basePath =
      '/data/data/com.vault.fide/files/usr/bin';

  /// Termux-like environment PATH builder
  Map<String, String> _termuxEnv() {
    final systemPath = Platform.environment['PATH'] ?? '';

    return {
      'PATH': '$basePath:$systemPath',
      'HOME': '/data/data/com.vault.fide/files/home',
      'PREFIX': '/data/data/com.vault.fide/files/usr',
      'LD_LIBRARY_PATH': '/data/data/com.vault.fide/files/usr/lib',
    };
  }

  // Future<ProcessResult> _runShell(String command) async {
  // const bashrc = '/data/data/com.vault.fide/files/usr/etc/bash.bashrc';
  
  // return await Process.run(
    // '/data/data/com.vault.fide/files/usr/bin/bash',
    // ['-c', 'source $bashrc 2>/dev/null; $command'],
    // environment: {
      // ...Platform.environment,
      // 'PATH': '/data/data/com.vault.fide/files/usr/bin',
      // 'HOME': '/data/data/com.vault.fide/files/home',
      // 'PREFIX': '/data/data/com.vault.fide/files/usr',
      // 'LD_LIBRARY_PATH': '/data/data/com.vault.fide/files/usr/lib',
    // },
  // );
// }

Future<ProcessResult> _runShell(String command) async {
  const prefix = '/data/data/com.vault.fide/files/usr';
  const home = '/data/data/com.vault.fide/files/home';

  final wrappedCommand = '''
    export HOME="$home"
    export PREFIX="$prefix"
    set +e
    command_not_found_handle() { return 127; }
    termux-setup-storage() { return 0; }
    read() { return 0; }
    apt() { return 0; }
    [ -f $prefix/etc/bash.bashrc ] && source $prefix/etc/bash.bashrc 2>/dev/null
    [ -f $home/.bashrc ] && source $home/.bashrc 2>/dev/null
    $command
  ''';

  return await Process.run(
    '$prefix/bin/bash',
    ['-c', wrappedCommand],
    environment: {
      ...Platform.environment,
      'PATH': '$prefix/bin',
      'HOME': home,
      'PREFIX': prefix,
      'LD_LIBRARY_PATH': '$prefix/lib',
    },
  );
}
  Future<void> runWhichTest(String command) async {
    setState(() {
      loading = true;
      output = "";
    });

    try {
      final whichPath = '$basePath/which';

      final whichExists = File(whichPath).existsSync();

      if (!whichExists) {
        setState(() {
          output = "❌ which binary NOT FOUND at: $whichPath";
          loading = false;
        });
        return;
      }

      ///  run using Termux-like shell
      final result = await _runShell('which $command');

      setState(() {
        output = """
🔎 Command Tested: $command

📍 which path: $whichPath
📦 exitCode: ${result.exitCode}

📤 STDOUT:
${result.stdout}

📥 STDERR:
${result.stderr}
""";
        loading = false;
      });
    } catch (e) {
      setState(() {
        output = "❌ ERROR: $e";
        loading = false;
      });
    }
  }

  Future<void> runPreInstallCheck(String command) async {
    setState(() {
      loading = true;
      output = "";
    });

    try {
      /// 🔥 Termux-style which via shell
      final result = await _runShell('which $command');

      setState(() {
        output = """
🧪 Termux-style PreInstall Check

🔎 command: $command
📦 exitCode: ${result.exitCode}

📤 STDOUT:
${result.stdout}

📥 STDERR:
${result.stderr}

🧠 PATH USED:
${_termuxEnv()['PATH']}
""";
        loading = false;
      });
    } catch (e) {
      setState(() {
        output = "❌ ERROR: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Which Debug Tool (Termux Style)"),
  actions: [
    IconButton(
      icon: const Icon(Icons.home),
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const IntroGate()),
          (route) => false,
        );
      },
    ),
  ],
),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Enter command (e.g. flutter, ls, git)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () => runWhichTest(controller.text),
                    child: const Text("Run raw which"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () => runPreInstallCheck(controller.text),
                    child: const Text("Run PreInstall check"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (loading) const CircularProgressIndicator(),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.black,
                  child: Text(
                    output,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

