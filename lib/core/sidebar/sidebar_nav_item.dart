import 'package:flutter/widgets.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'sidebar_contribution.dart';
import 'sidebar_region.dart';

abstract class SidebarNavItem extends SidebarContribution {
  /// Icon
  Widget? get icon;

  /// Label
  String get label;

  /// Badge (optional)
  int? get badgeCount => null;

  String? get panelId => null;

  /// Click handler
  void onSelect(EditorContext context);

  /// Selection state
  bool isSelected(EditorContext context);

  @override
  SidebarRegion get region => SidebarRegion.leftColumn;
}
