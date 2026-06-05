import 'package:flutter/widgets.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'sidebar_region.dart';

abstract class SidebarContribution {
  /// Unique ID
  String get id;

  /// Where it belongs
  SidebarRegion get region;

  /// Order in UI
  int get order => 0;

  /// Visibility
  bool get visible => true;

  /// Lifecycle init
  @mustCallSuper
  Future<void> prepare(EditorContext context) async {}

  /// Cleanup
  Future<void> dispose() async {}
}
