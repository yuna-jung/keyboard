import 'package:flutter_test/flutter_test.dart';

import 'package:font_keyboard/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const FontKeyboardApp());
    expect(find.text('Font Keyboard'), findsOneWidget);
  });
}
