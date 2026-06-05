import 'package:flutter/material.dart';
import 'package:flutter_studio/core/editor_context.dart';

abstract class BottomItem {
  /// Unique id
  String get id;

  /// Display title
  String get title;

  /// Optional icon
  Widget? get icon;

  /// Visibility
  bool get visible => true;

  /// Enabled state
  bool get enabled => true;

  /// Sort order
  int get order => 0;

  /// Persistent tab
  bool get keepAlive => true;

  /// Prepare resources
  @mustCallSuper
  Future<void> prepare(EditorContext context) async {}

  /// Build content
  Widget build(BuildContext context, EditorContext editorContext);

  /// Called when selected
  Future<void> onSelected(EditorContext context) async {}

  /// Called when unselected
  Future<void> onUnselected(EditorContext context) async {}

  /// Dispose resources
  Future<void> dispose() async {}
}
