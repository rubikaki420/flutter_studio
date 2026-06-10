import 'dart:convert';


class ProjectModel {
  final String path;
  final String language;
  final String timestamp;

  ProjectModel({
    required this.path,
    required this.language,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    "path": path,
    "language": language,
    "timestamp": timestamp,
  };

  static ProjectModel fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      path: map["path"],
      language: map["language"],
      timestamp: map["timestamp"],
    );
  }

  String encode() => jsonEncode(toMap());

  static ProjectModel decode(String data) =>
      ProjectModel.fromMap(jsonDecode(data));
}

