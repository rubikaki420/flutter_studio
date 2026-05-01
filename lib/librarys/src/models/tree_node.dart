class TreeNode<T> {
  static const String nodesIdSeparator = ":";

  int _id = 0;
  static int _lastId = 0;

  TreeNode<T>? _parent;
  final List<TreeNode<T>> _children = [];

  T value;
  bool isExpanded;
  bool isSelected;
  bool isSelectable;

  TreeNode({
    required this.value,
    this.isExpanded = false,
    this.isSelected = false,
    this.isSelectable = true,
    List<TreeNode<T>>? children,
  }) {
    _id = _generateId();
    if (children != null) {
      addChildren(children);
    }
  }

  static int _generateId() {
    return ++_lastId;
  }

  int get id => _id;

  TreeNode<T>? get parent => _parent;

  List<TreeNode<T>> get children => _children;

  TreeNode<T> addChild(TreeNode<T> child) {
    child._parent = this;
    _children.add(child);
    return this;
  }

  TreeNode<T> addChildren(Iterable<TreeNode<T>> childrenToAdd) {
    for (var child in childrenToAdd) {
      addChild(child);
    }
    return this;
  }

  TreeNode<T>? childAt(int index) {
    if (index >= 0 && index < _children.length) {
      return _children[index];
    }
    return null;
  }

  void deleteAllChildren() {
    for (var child in _children) {
      child._parent = null;
    }
    _children.clear();
  }

  int deleteChild(TreeNode<T> child) {
    for (int i = 0; i < _children.length; i++) {
      if (child.id == _children[i].id) {
        _children[i]._parent = null;
        _children.removeAt(i);
        return i;
      }
    }
    return -1;
  }

  bool get isLeaf => _children.isEmpty;

  int get size => _children.length;

  String get path {
    final StringBuffer pathStr = StringBuffer();
    TreeNode<T>? node = this;
    while (node?.parent != null) {
      pathStr.write(node!.id);
      node = node.parent;
      if (node?.parent != null) {
        pathStr.write(nodesIdSeparator);
      }
    }
    return pathStr.toString();
  }

  int get level {
    int level = 0;
    TreeNode<T>? root = this;
    while (root?.parent != null) {
      root = root!.parent;
      level++;
    }
    return level;
  }

  bool get isRoot => _parent == null;

  bool get isFirstChild {
    if (!isRoot) {
      return _parent!._children.first.id == id;
    }
    return false;
  }

  bool get isLastChild {
    if (!isRoot) {
      return _parent!._children.last.id == id;
    }
    return false;
  }

  TreeNode<T> get root {
    TreeNode<T> rootNode = this;
    while (rootNode.parent != null) {
      rootNode = rootNode.parent!;
    }
    return rootNode;
  }
}
