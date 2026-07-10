import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/app/app.dart';

void main() {
  testWidgets('NexusApp renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const NexusApp());
    expect(find.text('Nexus'), findsOneWidget);
  });
}
