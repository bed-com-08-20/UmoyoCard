import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umoyocard/main.dart';
import 'package:umoyocard/screens/login/login_screen.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      initialRoute: '/login', // Provide the required parameter
    ));

    // Since your app doesn't actually have a counter, you'll need to update
    // these expectations to match your actual app's behavior
    expect(find.text('Welcome to UmoyoCard'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
