import 'package:flutter_test/flutter_test.dart';
import 'package:auto_workshop/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoWorkshopApp());
    expect(find.text('Auto Workshop'), findsOneWidget);
  });
}
