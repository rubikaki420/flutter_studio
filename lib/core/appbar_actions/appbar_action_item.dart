import 'package:flutter/material.dart';
import 'package:flutter_studio/core/editor_context.dart';

abstract class AppbarActionItem {
  /// Unique ID
  String get id;

  /// Display label
  String get label;

  /// Optional subtitle
  String? get subtitle => null;

  /// Default visibility (can be overridden by isVisible)
  bool get visible => true;

  /// Enabled state
  bool get enabled => true;

  /// Action icon
  Widget? get icon;

  /// Execute on UI thread or not
  bool get requiresUIThread => true;

  /// Sort order
  int get order => 0;

  bool isVisible(EditorContext context) => visible;

  bool canExecute(EditorContext context) => enabled;

  /// Prepare action state
  @mustCallSuper
  Future<void> prepare(EditorContext context) async {}

  /// Execute action
  Future<dynamic> execute(EditorContext context);

  /// Post execute callback
  Future<void> postExecute(EditorContext context, dynamic result) async {}

  /// Dispose resources
  Future<void> dispose() async {}

  /// Optional custom widget
  Widget? buildActionView(EditorContext context) => null;

  /// Main lifecycle runner
  Future<dynamic> run(EditorContext context) async {
    await prepare(context);

    if (!canExecute(context)) {
      return null;
    }

    final result = await execute(context);

    await postExecute(context, result);

    context.actionsRegistry?.refresh();

    return result;
  }
}
