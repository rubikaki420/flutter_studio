
import 'package:flutter/material.dart';
import 'models/tree_node.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';

typedef NodeBuilder<T> = Widget Function(BuildContext context, TreeNode<T> node);
typedef NodeTapCallback<T> = void Function(TreeNode<T> node);
typedef NodeLongPressCallback<T> = void Function(TreeNode<T> node);
typedef NodeExpandCallback<T> = Future<void> Function(TreeNode<T> node);

class TreeView<T> extends StatefulWidget {
  final TreeNode<T> root;
  final NodeBuilder<T> builder;
  final NodeTapCallback<T>? onNodeTap;
  final NodeLongPressCallback<T>? onNodeLongPress;

  /// Called when a directory node is expanded for the first time (lazy load).
  final NodeExpandCallback<T>? onNodeExpand;

  final bool use2dScroll;
  final bool enableAutoToggle;
  final EdgeInsetsGeometry padding;
  final double indentWidth;
  final bool showTopNode;
  final ScrollController? verticalScrollController;
  final ScrollController? horizontalScrollController;

  const TreeView({
    super.key,
    required this.root,
    required this.builder,
    this.onNodeTap,
    this.onNodeLongPress,
    this.onNodeExpand,
    this.use2dScroll = true,
    this.enableAutoToggle = true,
    this.padding = EdgeInsets.zero,
    this.indentWidth = 20.0,
    this.showTopNode = true,
    this.verticalScrollController,
    this.horizontalScrollController,
  });

  @override
  State<TreeView<T>> createState() => TreeViewState<T>();
}

class TreeViewState<T> extends State<TreeView<T>> {
  // Which node is currently hovered (for hover highlight)
  int? _hoveredId;

  void toggleNode(TreeNode<T> node) {
    setState(() => node.isExpanded = !node.isExpanded);
  }

  void expandAll() => setState(() => _expandNode(widget.root, true));

  void collapseAll() => setState(() {
        for (var c in widget.root.children) {
          _collapseNode(c, true);
        }
        if (widget.showTopNode) widget.root.isExpanded = false;
      });

  void _expandNode(TreeNode<T> node, bool deep) {
    node.isExpanded = true;
    if (deep) {
      for (var c in node.children) {
        _expandNode(c, deep);
      }
    }
  }

  void _collapseNode(TreeNode<T> node, bool deep) {
    node.isExpanded = false;
    if (deep) {
      for (var c in node.children) {
        _collapseNode(c, deep);
      }
    }
  }

  Future<void> _handleTap(TreeNode<T> node) async {
    if (widget.onNodeTap != null) widget.onNodeTap!(node);

    if (widget.enableAutoToggle) {
      if (!node.isExpanded &&
          !node.childrenLoaded &&
          widget.onNodeExpand != null) {
        // Lazy load
        setState(() => node.isLoading = true);
        await widget.onNodeExpand!(node);
        setState(() {
          node.isLoading = false;
          node.childrenLoaded = true;
          node.isExpanded = true;
        });
      } else {
        setState(() => node.isExpanded = !node.isExpanded);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tree = widget.showTopNode
        ? _buildNode(widget.root)
        : _buildNodeList(widget.root.children);

    return SingleChildScrollView(
      controller: widget.verticalScrollController,
      padding: widget.padding,
      child: Align(
        alignment: Alignment.topLeft,
        child: widget.use2dScroll
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: widget.horizontalScrollController,
                child: tree,
              )
            : tree,
      ),
    );
  }

  Widget _buildNodeList(List<TreeNode<T>> nodes) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: nodes.map(_buildNode).toList(),
      );

  Widget _buildNode(TreeNode<T> node) {
    final depth = node.isRoot ? 0 : node.level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredId = node.id),
          onExit: (_) => setState(() => _hoveredId = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleTap(node),
            onLongPress: () => widget.onNodeLongPress?.call(node),
            onSecondaryTap: () => widget.onNodeLongPress?.call(node),
            child: Container(
              color: _hoveredId == node.id
                  ? AppColors.white.withValues(alpha: 0.05)
                  : AppColors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indent lines
                  if (!node.isRoot)
                    _IndentLines(
                      depth: depth,
                      indentWidth: widget.indentWidth,
                      node: node,
                    ),
                  // Expand/Collapse arrow
                  if (!node.isLeaf || node.isLoading)
                    _ExpandArrow(node: node)
                  else
                    SizedBox(width: node.isRoot ? 0 : 16),
                  // Node content
                  widget.builder(context, node),
                ],
              ),
            ),
          ),
        ),
        // Children
        if (node.isExpanded && node.children.isNotEmpty)
          _buildNodeList(node.children),
      ],
    );
  }
}

// ─── Expand/Collapse Arrow ────────────────────────────────

class _ExpandArrow<T> extends StatelessWidget {
  final TreeNode<T> node;
  const _ExpandArrow({required this.node});

  @override
  Widget build(BuildContext context) {
    if (node.isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    return AnimatedRotation(
      turns: node.isExpanded ? 0.25 : 0,
      duration: const Duration(milliseconds: 150),
      child: const Icon(Icons.chevron_right, size: 16, color: AppColors.vscodeGutter),
    );
  }
}


class _IndentLines<T> extends StatelessWidget {
  final int depth;
  final double indentWidth;
  final TreeNode<T> node;

  const _IndentLines({
    required this.depth,
    required this.indentWidth,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: depth * indentWidth,
      height: 22,
      child: CustomPaint(
        painter: _IndentLinePainter(
          depth: depth,
          indentWidth: indentWidth,
          node: node,
        ),
      ),
    );
  }
}

class _IndentLinePainter<T> extends CustomPainter {
  final int depth;
  final double indentWidth;
  final TreeNode<T> node;

  _IndentLinePainter({
    required this.depth,
    required this.indentWidth,
    required this.node,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.dividerGrey
      ..strokeWidth = 1.0;

    // Draw vertical guide lines for each ancestor level
    TreeNode<T>? current = node.parent;
    final levels = <int, bool>{};
    int lvl = depth - 1;

    while (current != null && !current.isRoot) {
      levels[lvl] = !current.isLastChild;
      current = current.parent;
      lvl--;
    }

    for (int i = 1; i < depth; i++) {
      final x = (i * indentWidth) - (indentWidth / 2);
      if (levels[i] == true) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IndentLinePainter old) => false;
}
