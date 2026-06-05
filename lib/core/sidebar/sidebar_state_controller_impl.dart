// sidebar_state_controller_impl.dart

import 'dart:async';
import 'package:flutter_studio/core/sidebar/sidebar_state_controller.dart';

class SidebarStateControllerImpl implements SidebarStateController {
  String? _activeNavItemId;
  String? _activePanelId;
  bool _isSidebarVisible = true;

  final _controller = StreamController<void>.broadcast();

  @override
  String? get activeNavItemId => _activeNavItemId;

  @override
  String? get activePanelId => _activePanelId;

  @override
  bool get isSidebarVisible => _isSidebarVisible;

  @override
  Stream<void> get onChanged => _controller.stream;

  @override
  void selectNavItem(String id) {
    _activeNavItemId = id;
    _isSidebarVisible = true; // Open sidebar when item is selected
    _controller.add(null);
  }

  @override
  void openPanel(String id) {
    _activePanelId = id;
    _controller.add(null);
  }

  @override
  void toggleSidebar() {
    _isSidebarVisible = !_isSidebarVisible;
    _controller.add(null);
  }

  @override
  void restore() {
    // SharedPreferences থেকে load করুন
  }

  @override
  void save() {
    // SharedPreferences এ save করুন
  }

  void dispose() => _controller.close();
}
