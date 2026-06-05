import 'package:flutter/material.dart';
import 'package:flutter_studio/core/editor_context.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_registry.dart';
import 'package:flutter_studio/core/bottom_bar/bottom_item.dart';
import 'package:flutter_studio/core/utils/app_colors.dart';

class EditorBottomPanel extends StatefulWidget {
  final BottomRegistry registry;
  final EditorContext contextData;

  const EditorBottomPanel({
    super.key,
    required this.registry,
    required this.contextData,
  });

  @override
  State<EditorBottomPanel> createState() => _EditorBottomPanelState();
}

class _EditorBottomPanelState extends State<EditorBottomPanel> {
  double height = 100;

  final double minHeight = 55;
  final double maxHeight = 600;

  String? selectedItemId;

  @override
  void initState() {
    super.initState();

    selectedItemId = widget.registry.selectedItemId;

    final items = widget.registry.getItems();
    if (selectedItemId == null && items.isNotEmpty) {
      selectedItemId = items.first.id;
      widget.registry.selectItemById(selectedItemId);
    }

    widget.registry.addListener(_onRegistryChanged);
  }

  void _onRegistryChanged() {
    final items = widget.registry.getItems();

    setState(() {
      selectedItemId = widget.registry.selectedItemId;

      if (selectedItemId != null &&
          widget.registry.findItem(selectedItemId!) == null) {
        if (items.isNotEmpty) {
          selectedItemId = items.first.id;
          widget.registry.selectItemById(selectedItemId);
        } else {
          selectedItemId = null;
          widget.registry.selectItemById(null);
        }
      } else if (selectedItemId == null && items.isNotEmpty) {
        selectedItemId = items.first.id;
        widget.registry.selectItemById(selectedItemId);
      }
    });
  }

  @override
  void dispose() {
    widget.registry.removeListener(_onRegistryChanged);
    super.dispose();
  }

  final _dummyListenable = ChangeNotifier();

  BottomItem? get selectedItem =>
      widget.registry.findItem(selectedItemId ?? '');

  void selectItem(BottomItem item) async {
    if (selectedItemId == item.id) return;

    await selectedItem?.onUnselected(widget.contextData);

    widget.registry.selectItemById(item.id);

    await item.onSelected(widget.contextData);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.registry.getItems()
      ..sort((a, b) => a.order.compareTo(b.order));

    final visibleItems = items.where((e) => e.visible).toList();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (details) {
                setState(() {
                  height -= details.delta.dy;

                  if (height < minHeight) height = minHeight;
                  if (height > maxHeight) height = maxHeight;
                });
              },
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: visibleItems.length,
                              itemBuilder: (context, index) {
                                final item = visibleItems[index];
                                final isActive = item.id == selectedItemId;

                                return ListenableBuilder(
                                  listenable: item is Listenable
                                      ? item as Listenable
                                      : _dummyListenable,
                                  builder: (context, _) {
                                    return GestureDetector(
                                      onTap: () => selectItem(item),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: isActive
                                              ? AppColors.vscodeBackground
                                              : AppColors.transparent,
                                        ),
                                        child: Row(
                                          children: [
                                            if (item.icon != null) ...[
                                              item.icon!,
                                              const SizedBox(width: 6),
                                            ],
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                fontWeight: isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            child: IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: "Add item",
                              onPressed: () {
                                widget.contextData.language?.sessionManager
                                    ?.createSession();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: Stack(
                children: visibleItems.map((item) {
                  final isActive = item.id == selectedItemId;

                  return Offstage(
                    offstage: !isActive,
                    child: TickerMode(
                      enabled: isActive,
                      child: item.build(context, widget.contextData),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
