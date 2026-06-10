
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
      home: const IntroGate(),
    );
  }
}
