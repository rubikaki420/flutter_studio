import 'package:flutter/foundation.dart';
import 'bottom_item.dart';
import 'bottom_registry.dart';

class BottomRegistryImpl extends ChangeNotifier implements BottomRegistry {
  final Map<String, BottomItem> _items = {};
  String? _selectedItemId;

  @override
  String? get selectedItemId => _selectedItemId;

  @override
  void selectItemById(String? id) {
    if (_selectedItemId == id) return;
    _selectedItemId = id;
    notifyListeners();
  }

  @override
  bool registerItem(BottomItem item) {
    if (_items.containsKey(item.id)) return false;
    _items[item.id] = item;
    notifyListeners();
    return true;
  }

  @override
  bool unregisterItem(BottomItem item) {
    final removed = _items.remove(item.id) != null;
    if (removed) notifyListeners();
    return removed;
  }

  @override
  void refresh() {
    notifyListeners();
  }

  @override
  bool unregisterItemById(String id) {
    final removed = _items.remove(id) != null;
    if (removed) notifyListeners();
    return removed;
  }

  @override
  BottomItem? findItem(String id) => _items[id];

  @override
  List<BottomItem> getItems() =>
      _items.values.toList()..sort((a, b) => a.order.compareTo(b.order));

  @override
  void clearItems() {
    _items.clear();
    notifyListeners();
  }
}
