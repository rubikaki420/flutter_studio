// lib/core/sidebar/explorer/explorer_nav_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/sidebar/sidebar_nav_item.dart';

class ExplorerNavItem extends SidebarNavItem {
  bool _selected = false;

  @override
  String get id => 'universal.explorer.nav';

  @override
  String get label => 'Explorer';

  @override
  Widget? get icon => const Icon(Icons.folder_outlined);

  @override
  int get order => 0;

  @override
  String? get panelId => 'universal.explorer.panel';

  @override
  void onSelect(EditorContext context) {
    _selected = !_selected;
  }

  @override
  bool isSelected(EditorContext context) => _selected;
}
