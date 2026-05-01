import 'package:flutter/material.dart';
import 'models/tree_node.dart';

typedef NodeBuilder<T> = Widget Function(
    BuildContext context, TreeNode<T> node);
typedef NodeTapCallback<T> = void Function(TreeNode<T> node);
typedef NodeLongPressCallback<T> = void Function(TreeNode<T> node);

class TreeView<T> extends StatefulWidget {
  final TreeNode<T> root;
  final NodeBuilder<T> builder;
  final NodeTapCallback<T>? onNodeTap;
  final NodeLongPressCallback<T>? onNodeLongPress;
  final bool use2dScroll;
  final bool enableAutoToggle;
  final EdgeInsetsGeometry padding;
  final Widget? nodeIndentWidget;
  final double indentWidth;
  final ScrollController? verticalScrollController;
  final ScrollController? horizontalScrollController;
  
  final bool showTopNode;

  const TreeView({
    super.key,
    required this.root,
    required this.builder,
    this.onNodeTap,
    this.onNodeLongPress,
    this.use2dScroll = true,
    this.enableAutoToggle = true,
    this.padding = EdgeInsets.zero,
    this.nodeIndentWidget,
    this.indentWidth = 20.0,
    this.verticalScrollController,
    this.horizontalScrollController,
    this.showTopNode = true,
  });

  @override
  State<TreeView<T>> createState() => TreeViewState<T>();
}

class TreeViewState<T> extends State<TreeView<T>> {
  @override
  void initState() {
    super.initState();
  }

  void toggleNode(TreeNode<T> node) {
    setState(() {
      node.isExpanded = !node.isExpanded;
    });
  }

  void expandAll() {
    setState(() {
      _expandNode(widget.root, true);
    });
  }

  void collapseAll() {
    setState(() {
      for (var child in widget.root.children) {
        _collapseNode(child, true);
      }
      if (widget.showTopNode) {
        widget.root.isExpanded = false;
      }
    });
  }

  void _expandNode(TreeNode<T> node, bool includeSubnodes) {
    node.isExpanded = true;
    if (includeSubnodes) {
      for (var child in node.children) {
        _expandNode(child, includeSubnodes);
      }
    }
  }

  void _collapseNode(TreeNode<T> node, bool includeSubnodes) {
    node.isExpanded = false;
    if (includeSubnodes) {
      for (var child in node.children) {
        _collapseNode(child, includeSubnodes);
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
      child: Container(
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

  Widget _buildNodeList(List<TreeNode<T>> nodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: nodes.map((node) => _buildNode(node)).toList(),
    );
  }

  Widget _buildNode(TreeNode<T> node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.onNodeTap != null) {
              widget.onNodeTap!(node);
            }
            if (widget.enableAutoToggle) {
              toggleNode(node);
            }
          },
          onLongPress: () {
            if (widget.onNodeLongPress != null) {
              widget.onNodeLongPress!(node);
            }
          },
          child: widget.builder(context, node),
        ),
        if (node.isExpanded && node.children.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.nodeIndentWidget ?? SizedBox(width: widget.indentWidth),
              Flexible(
                child: _buildNodeList(node.children),
              ),
            ],
          )
      ],
    );
  }
}
