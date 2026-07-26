import 'package:flutter_test/flutter_test.dart';
import 'package:nutmate/main.dart';

void main() {
  testWidgets('NutmateApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NutmateApp());
    expect(find.byType(NutmateApp), findsOneWidget);
  });
}
