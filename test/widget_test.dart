import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/app/app.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';

void main() {
  testWidgets('NexusApp renders without errors', (WidgetTester tester) async {
    final authController = AuthController();
    await tester.pumpWidget(NexusApp(authController: authController));
    expect(find.text('Nexus'), findsOneWidget);
  });
}
