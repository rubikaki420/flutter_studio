//core/utils/project_storage.dart
import 'package:flutter_studio/core/models/project_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectStorage {
  static const _recentKey = "recent_projects";
  static const _lastKey = "last_project";

  static Future<void> saveProject(String path, String language) async {
    final prefs = await SharedPreferences.getInstance();

    final list = prefs.getStringList(_recentKey) ?? [];

    // remove duplicate
    list.removeWhere((e) => e.contains(path));

    final data = ProjectModel(
      path: path,
      language: language,
      timestamp: DateTime.now().toIso8601String(),
    ).encode();

    list.insert(0, data);

    await prefs.setStringList(_recentKey, list);
    await prefs.setString(_lastKey, path);
  }

  static Future<String?> getLastProject() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastKey);
  }

  static Future<List<ProjectModel>> getRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];

    return list.map((e) => ProjectModel.decode(e)).toList();
  }
}
