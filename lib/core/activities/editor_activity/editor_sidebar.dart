import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/sidebar/sidebar_registry.dart';
import 'package:flutter_studio/core/sidebar/sidebar_state_controller.dart';

class EditorSidebar extends StatefulWidget {
  final SidebarRegistry registry;
  final SidebarStateController controller;
  final EditorContext editorContext;

  const EditorSidebar({
    super.key,
    required this.registry,
    required this.controller,
    required this.editorContext,
  });

  @override
  State<EditorSidebar> createState() => _EditorSidebarState();
}

class _EditorSidebarState extends State<EditorSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const double _navBarWidth = 50.0;
  static const double _panelWidth = 250.0;
  static const double _totalWidth = _navBarWidth + 1 + _panelWidth + 1;
  static const Duration _duration = Duration(milliseconds: 260);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _duration,
      value: widget.controller.isSidebarVisible ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _syncAnimation(bool visible) {
    if (visible && _animationController.value < 1.0) {
      _animationController.forward();
    } else if (!visible && _animationController.value > 0.0) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.controller.onChanged,
      builder: (context, snapshot) {
        _syncAnimation(widget.controller.isSidebarVisible);

        final navItems = widget.registry.getNavItems();
        final activeNavId =
            widget.controller.activeNavItemId ??
            (navItems.isNotEmpty ? navItems.first.id : null);
        final activePanelId =
            widget.controller.activePanelId ??
            (navItems.isNotEmpty
                ? navItems
                      .firstWhere(
                        (i) => i.id == activeNavId,
                        orElse: () => navItems.first,
                      )
                      .panelId
                : null);

        final activePanel = widget.registry
            .getPanels()
            .where((p) => p.id == activePanelId)
            .firstOrNull;

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              width: _animation.value * _totalWidth,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: _totalWidth,
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: _totalWidth,
            child: Row(
              children: [
                Container(
                  width: _navBarWidth,
                  color: AppColors.vscodeBackground,
                  child: Column(
                    children: navItems.map((item) {
                      final selected = item.id == activeNavId;
                      return GestureDetector(
                        onTap: () {
                          item.onSelect(widget.editorContext);
                          widget.controller.selectNavItem(item.id);
                          if (item.panelId != null) {
                            widget.controller.openPanel(item.panelId!);
                          }
                        },
                        child: Container(
                          width: _navBarWidth,
                          height: _navBarWidth,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: selected
                                    ? AppColors.blue
                                    : AppColors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: IconTheme(
                            data: IconThemeData(
                              color: selected
                                  ? AppColors.text
                                  : AppColors.overlay0,
                              size: 24,
                            ),
                            child: Center(
                              child:
                                  item.icon ?? const Icon(Icons.help_outline),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                Container(width: 1, color: AppColors.overlay),

                if (activePanel != null)
                  SizedBox(
                    width: _panelWidth,
                    child: Container(
                      color: AppColors.vscodeBackground,
                      child: activePanel.build(context, widget.editorContext),
                    ),
                  ),

                Container(width: 1, color: AppColors.overlay),
              ],
            ),
          ),
        );
      },
    );
  }
}
