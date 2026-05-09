import 'package:flutter_test/flutter_test.dart';
import 'package:alis_grandson_app/src/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Fixed: Added the required parameters 'isAdminLoggedIn' and 'isUserLoggedIn'.
    await tester.pumpWidget(const MyApp(
      isAdminLoggedIn: false,
      isUserLoggedIn: false,
    ));

    // Verify that the landing page text is present.
    // updated to match the redesigned title
    expect(find.text('ALI GRANDSONS'), findsOneWidget);
    expect(find.text('CUSTOMER LOGIN'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
  });
}
