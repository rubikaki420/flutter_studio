import 'package:flutter/foundation.dart';
import 'bottom_item.dart';

abstract class BottomRegistry implements Listenable {
  String? get selectedItemId;

  void selectItemById(String? id);

  bool registerItem(BottomItem item);

  bool unregisterItem(BottomItem item);

  bool unregisterItemById(String id);

  BottomItem? findItem(String id);

  List<BottomItem> getItems();

  void clearItems();
  void refresh();
}
