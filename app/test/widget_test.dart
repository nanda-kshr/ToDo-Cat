import 'package:flutter_test/flutter_test.dart';
import 'package:todocat/main.dart';

void main() {
  testWidgets('TodoCatApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoCatApp());
    expect(find.byType(TodoCatApp), findsOneWidget);
  });
}
