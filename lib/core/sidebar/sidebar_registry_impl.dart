// // sidebar_registry_impl.dart

import 'package:flutter_studio/core/sidebar/sidebar_contribution.dart';
import 'package:flutter_studio/core/sidebar/sidebar_nav_item.dart';
import 'package:flutter_studio/core/sidebar/sidebar_panel.dart';
import 'package:flutter_studio/core/sidebar/sidebar_region.dart';
import 'package:flutter_studio/core/sidebar/sidebar_registry.dart';

// class SidebarRegistryImpl implements SidebarRegistry {
// final Map<String, SidebarContribution> _items = {};

// @override
// bool register(SidebarContribution item) {
// if (_items.containsKey(item.id)) return false;
// _items[item.id] = item;
// return true;
// }

// @override
// bool unregister(String id) => _items.remove(id) != null;

// @override
// SidebarContribution? find(String id) => _items[id];

// @override
// List<SidebarContribution> getByRegion(SidebarRegion region) =>
// _items.values
// .where((e) => e.region == region && e.visible)
// .toList()
// ..sort((a, b) => a.order.compareTo(b.order));

// @override
// List<SidebarNavItem> getNavItems() =>
// _items.values.whereType<SidebarNavItem>().toList()
// ..sort((a, b) => a.order.compareTo(b.order));

// @override
// List<SidebarPanel> getPanels() =>
// _items.values.whereType<SidebarPanel>().toList();

// @override
// void clear() => _items.clear();
// }
import 'package:flutter/foundation.dart';

class SidebarRegistryImpl extends ChangeNotifier implements SidebarRegistry {
  final Map<String, SidebarContribution> _items = {};

  @override
  bool register(SidebarContribution item) {
    if (_items.containsKey(item.id)) return false;

    _items[item.id] = item;

    notifyListeners();

    return true;
  }

  @override
  bool unregister(String id) {
    final removed = _items.remove(id) != null;

    if (removed) {
      notifyListeners();
    }

    return removed;
  }

  @override
  SidebarContribution? find(String id) => _items[id];

  @override
  List<SidebarContribution> getByRegion(SidebarRegion region) =>
      _items.values.where((e) => e.region == region && e.visible).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  @override
  List<SidebarNavItem> getNavItems() =>
      _items.values.whereType<SidebarNavItem>().toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  @override
  List<SidebarPanel> getPanels() =>
      _items.values.whereType<SidebarPanel>().toList();

  @override
  void clear() {
    _items.clear();
    notifyListeners();
  }

  @override
  void refresh() {
    notifyListeners();
  }
}
