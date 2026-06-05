
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
  bool isLoading; // lazy loading spinner
  bool _childrenLoaded; // has children been loaded yet

  TreeNode({
    required this.value,
    this.isExpanded = false,
    this.isSelected = false,
    this.isSelectable = true,
    this.isLoading = false,
    bool childrenLoaded = false,
    List<TreeNode<T>>? children,
  }) : _childrenLoaded = childrenLoaded {
    _id = _generateId();
    if (children != null) {
      addChildren(children);
      _childrenLoaded = true;
    }
  }

  static int _generateId() => ++_lastId;

  int get id => _id;
  TreeNode<T>? get parent => _parent;
  List<TreeNode<T>> get children => _children;
  // ignore: unnecessary_getters_setters
  bool get childrenLoaded => _childrenLoaded;
  set childrenLoaded(bool v) => _childrenLoaded = v;

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

  TreeNode<T>? childAt(int index) =>
      (index >= 0 && index < _children.length) ? _children[index] : null;

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
  bool get isRoot => _parent == null;
  bool get isFirstChild => !isRoot && _parent!._children.first.id == id;
  bool get isLastChild => !isRoot && _parent!._children.last.id == id;

  int get level {
    int lvl = 0;
    TreeNode<T>? r = this;
    while (r?.parent != null) {
      r = r!.parent;
      lvl++;
    }
    return lvl;
  }

  TreeNode<T> get root {
    TreeNode<T> r = this;
    while (r.parent != null) {
      r = r.parent!;
    }
    return r;
  }

  String get path {
    final buf = StringBuffer();
    TreeNode<T>? node = this;
    while (node?.parent != null) {
      buf.write(node!.id);
      node = node.parent;
      if (node?.parent != null) buf.write(nodesIdSeparator);
    }
    return buf.toString();
  }
}
