import 'package:flutter/widgets.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'sidebar_contribution.dart';
import 'sidebar_region.dart';

abstract class SidebarPanel extends SidebarContribution {
  /// Build UI
  Widget build(BuildContext context, EditorContext editorContext);

  /// When opened
  Future<void> onOpen(EditorContext context) async {}

  /// When closed
  Future<void> onClose(EditorContext context) async {}

  /// Save state
  Future<Map<String, dynamic>> saveState() async => {};

  /// Restore state
  Future<void> restoreState(Map<String, dynamic> state) async {}

  @override
  SidebarRegion get region => SidebarRegion.content;
}
