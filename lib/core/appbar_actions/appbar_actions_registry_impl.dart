// import 'appbar_action_item.dart';
// import 'appbar_actions_registry.dart';

// class ActionsRegistryImpl implements ActionsRegistry {
// final Map<String, AppbarActionItem> _actions = {};
// final List<ActionExecListener> _listeners = [];

// @override
// bool registerAction(AppbarActionItem action) {
// if (_actions.containsKey(action.id)) return false;
// _actions[action.id] = action;
// return true;
// }

// @override
// bool unregisterAction(AppbarActionItem action) =>
// _actions.remove(action.id) != null;

// @override
// bool unregisterActionById(String id) => _actions.remove(id) != null;

// @override
// AppbarActionItem? findAction(String id) => _actions[id];

// @override
// Map<String, AppbarActionItem> getActions() => Map.unmodifiable(_actions);

// @override
// void clearActions() => _actions.clear();

// @override
// void registerActionExecListener(ActionExecListener listener) {
// if (!_listeners.contains(listener)) {
// _listeners.add(listener);
// }
// }

// @override
// void unregisterActionExecListener(ActionExecListener listener) {
// _listeners.remove(listener);
// }

// void notifyListeners(AppbarActionItem action, dynamic result) {
// for (var listener in _listeners) {
// listener.onExecute(action, result);
// }
// }
// }
import 'package:flutter/foundation.dart';
import 'appbar_action_item.dart';
import 'appbar_actions_registry.dart';

class ActionsRegistryImpl extends ChangeNotifier implements ActionsRegistry {
  final Map<String, AppbarActionItem> _actions = {};
  final List<ActionExecListener> _listeners = [];

  @override
  bool registerAction(AppbarActionItem action) {
    if (_actions.containsKey(action.id)) return false;

    _actions[action.id] = action;

    notifyListeners();

    return true;
  }

  @override
  bool unregisterAction(AppbarActionItem action) {
    final removed = _actions.remove(action.id) != null;

    if (removed) {
      notifyListeners();
    }

    return removed;
  }

  @override
  bool unregisterActionById(String id) {
    final removed = _actions.remove(id) != null;

    if (removed) {
      notifyListeners();
    }

    return removed;
  }

  @override
  AppbarActionItem? findAction(String id) => _actions[id];

  @override
  Map<String, AppbarActionItem> getActions() => Map.unmodifiable(_actions);

  @override
  void clearActions() {
    _actions.clear();
    notifyListeners();
  }

  @override
  void refresh() {
    notifyListeners();
  }

  @override
  void registerActionExecListener(ActionExecListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  @override
  void unregisterActionExecListener(ActionExecListener listener) {
    _listeners.remove(listener);
  }

  void notifyActionExecuted(AppbarActionItem action, dynamic result) {
    for (final listener in _listeners) {
      listener.onExecute(action, result);
    }
  }
}
