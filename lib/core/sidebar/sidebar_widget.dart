import 'package:flutter/widgets.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'sidebar_contribution.dart';
import 'sidebar_region.dart';

abstract class SidebarWidget extends SidebarContribution {
  /// UI
  Widget build(BuildContext context, EditorContext editorContext);

  /// Optional tap
  void onTap(EditorContext context) {}

  @override
  SidebarRegion get region;
}
