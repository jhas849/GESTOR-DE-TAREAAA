// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestor_tareas/screens/sign_in_screen.dart';

void main() {
  testWidgets('valida campos y permite entrar en la demo', (tester) async {
    var signedIn = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SignInScreen(
          demoMode: true,
          onDemoSignIn: () => signedIn = true,
        ),
      ),
    );

    await tester.tap(find.text('Entrar a la demo'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un correo valido.'), findsOneWidget);

    await tester.enterText(
        find.byType(TextFormField).at(0), 'demo@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'clave123');
    await tester.tap(find.text('Entrar a la demo'));
    await tester.pump();

    expect(signedIn, isTrue);
  });
}
