import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/core/widgets/home_activity_list_item.dart';
import '../language/language_registry.dart';

class HomeActivity extends StatelessWidget {
  const HomeActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final languages = LanguageRegistry.all;

    return Scaffold(
      backgroundColor: AppColors.vscodeSideBar,

      appBar: AppBar(
        title: const Text("Flutter Studio"),
        backgroundColor: AppColors.vscodeBackground,
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: languages.length,

        separatorBuilder: (context, index) => const SizedBox(height: 10),

        itemBuilder: (context, index) {
          final language = languages[index];

          return HomeActivityListItem(language: language);
        },
      ),
    );
  }
}
