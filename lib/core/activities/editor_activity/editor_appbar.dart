import 'package:flutter/material.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_action_item.dart';
import 'package:flutter_studio/core/appbar_actions/appbar_actions_registry.dart';

const double kAppbarHeight = 48.0;

class EditorAppbar extends StatefulWidget {
  final EditorContext context;
  final ActionsRegistry actionsRegistry;
  final VoidCallback? onMenuPressed;

  const EditorAppbar({
    super.key,
    required this.context,
    required this.actionsRegistry,
    this.onMenuPressed,
  });

  @override
  State<EditorAppbar> createState() => _EditorAppbarState();
}

class _EditorAppbarState extends State<EditorAppbar> {
  @override
  Widget build(BuildContext context) {
    final undoRedo = widget.context.activeUndoRedoController;

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.actionsRegistry,
        undoRedo ?? _dummyListenable,
      ]),
      builder: (context, _) {
        final actions =
            widget.actionsRegistry
                .getActions()
                .values
                .where((a) => a.isVisible(widget.context))
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));

        return Container(
          height: kAppbarHeight,
          color: AppColors.vscodeBackground,
          child: Row(
            children: [
              SizedBox(
                width: kAppbarHeight,
                height: kAppbarHeight,
                child: _MenuButton(onPressed: widget.onMenuPressed),
              ),

              Expanded(
                child: _ActionsScrollView(
                  actions: actions,
                  editorContext: widget.context,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final _dummyListenable = ChangeNotifier();

class _MenuButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _MenuButton({this.onPressed});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered ? AppColors.overlay : AppColors.transparent,
          child: Center(
            child: Icon(
              Icons.menu_rounded,
              size: 20,
              color: _hovered ? AppColors.text : AppColors.subtext0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionsScrollView extends StatelessWidget {
  final List<AppbarActionItem> actions;
  final EditorContext editorContext;

  const _ActionsScrollView({
    required this.actions,
    required this.editorContext,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: actions.map((action) {
            return _ActionChip(action: action, editorContext: editorContext);
          }).toList(),
        ),
      ),
    );
  }
}

class _ActionChip extends StatefulWidget {
  final AppbarActionItem action;
  final EditorContext editorContext;

  const _ActionChip({required this.action, required this.editorContext});

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _hovered = false;
  bool _running = false;

  Future<void> _handleTap() async {
    if (_running) return;
    if (!widget.action.canExecute(widget.editorContext)) return;

    setState(() => _running = true);

    try {
      await widget.action.run(widget.editorContext);
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If action provides a fully custom view, use it
    final customView = widget.action.buildActionView(widget.editorContext);
    if (customView != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: customView,
      );
    }

    final isEnabled = widget.action.canExecute(widget.editorContext);

    final effectiveColor = isEnabled
        ? (_hovered ? AppColors.text : AppColors.subtext1)
        : AppColors.surface2;

    final bgColor = _hovered && isEnabled
        ? AppColors.overlay
        : AppColors.transparent;

    final tooltipText = widget.action.subtitle?.trim() ?? '';

    Widget content = GestureDetector(
      onTap: isEnabled ? _handleTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_running)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.blue,
                ),
              )
            else if (widget.action.icon != null)
              SizedBox(
                width: 24,
                height: 24,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: IconTheme(
                    data: IconThemeData(size: 24, color: effectiveColor),
                    child: widget.action.icon!,
                  ),
                ),
              ),

            if (!_running &&
                widget.action.icon != null &&
                widget.action.label.isNotEmpty)
              const SizedBox(width: 5),

            if (widget.action.label.isNotEmpty)
              Text(
                widget.action.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontFamily: 'JetBrains Mono',
                  color: effectiveColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
          ],
        ),
      ),
    );

    if (tooltipText.isNotEmpty) {
      content = Tooltip(
        message: tooltipText,
        waitDuration: const Duration(milliseconds: 300),
        child: content,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: content,
    );
  }
}
