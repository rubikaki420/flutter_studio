// import 'appbar_action_item.dart';

// abstract class ActionsRegistry {
// bool registerAction(AppbarActionItem action);

// bool unregisterAction(AppbarActionItem action);

// bool unregisterActionById(String id);

// AppbarActionItem? findAction(
// String id,
// );

// Map<String, AppbarActionItem> getActions();

// void clearActions();

// void registerActionExecListener(
// ActionExecListener listener,
// );

// void unregisterActionExecListener(
// ActionExecListener listener,
// );
// }

import 'package:flutter/foundation.dart';
import 'appbar_action_item.dart';

abstract class ActionsRegistry implements Listenable {
  bool registerAction(AppbarActionItem action);

  bool unregisterAction(AppbarActionItem action);

  bool unregisterActionById(String id);

  AppbarActionItem? findAction(String id);

  Map<String, AppbarActionItem> getActions();

  void clearActions();

  void refresh();

  void registerActionExecListener(ActionExecListener listener);

  void unregisterActionExecListener(ActionExecListener listener);
}

abstract class ActionExecListener {
  void onExecute(AppbarActionItem action, dynamic result);
}
