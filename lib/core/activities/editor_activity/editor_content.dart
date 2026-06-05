import 'package:flutter/material.dart';

class TabbarContent extends StatefulWidget {
  final Widget content;
  const TabbarContent(this.content, {super.key});
  @override
  State<TabbarContent> createState() => _TabbarContentState();
}

class _TabbarContentState extends State<TabbarContent>
    with AutomaticKeepAliveClientMixin {
  //Very important for CodeForge @https://stackoverflow.com/questions/53011686/flutter-automatickeepaliveclientmixin-is-not-working-with-bottomnavigationbar
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.content;
  }

  @override
  bool get wantKeepAlive => true;
}
