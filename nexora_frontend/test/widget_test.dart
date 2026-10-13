import 'package:flutter_test/flutter_test.dart';

import 'package:product_app/main.dart';

void main() {
  testWidgets('App boots and shows the Nexora splash/login flow', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NxApp());
    await tester.pump(const Duration(seconds: 1));

    // The app should reach either the splash or the login screen —
    // both contain the brand name.
    expect(find.textContaining('Nexora'), findsWidgets);
  });
}
