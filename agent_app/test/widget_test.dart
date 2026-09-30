import 'package:flutter_test/flutter_test.dart';
import 'package:agent_app/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AgentApp());
    expect(find.text('تطبيق الوكيل'), findsOneWidget);
  });
}
