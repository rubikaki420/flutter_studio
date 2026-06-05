abstract class SidebarStateController {
  /// currently selected nav item
  String? get activeNavItemId;

  /// currently active panel
  String? get activePanelId;

  /// sidebar visibility
  bool get isSidebarVisible;

  /// select navigation item
  void selectNavItem(String id);

  /// open panel
  void openPanel(String id);

  /// toggle sidebar visibility
  void toggleSidebar();

  /// restore state
  void restore();

  /// persist state
  void save();

  Stream<void> get onChanged;
}
