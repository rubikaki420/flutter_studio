import 'sidebar_contribution.dart';
import 'sidebar_nav_item.dart';
import 'sidebar_panel.dart';
import 'sidebar_region.dart';

// abstract class SidebarRegistry {
// bool register(SidebarContribution item);

// bool unregister(String id);

// SidebarContribution? find(String id);

// List<SidebarContribution> getByRegion(SidebarRegion region);

// List<SidebarNavItem> getNavItems();

// List<SidebarPanel> getPanels();

// void clear();
// }
import 'package:flutter/foundation.dart';

abstract class SidebarRegistry implements Listenable {
  bool register(SidebarContribution item);

  bool unregister(String id);

  SidebarContribution? find(String id);

  List<SidebarContribution> getByRegion(SidebarRegion region);

  List<SidebarNavItem> getNavItems();

  List<SidebarPanel> getPanels();

  void clear();

  void refresh();
}
