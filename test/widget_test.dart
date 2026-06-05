import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_studio/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title is present.
    expect(find.text('Flutter Studio'), findsOneWidget);
  });
}
