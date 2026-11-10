import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:reliefroute/main.dart';

void main() {
  testWidgets('shows the ReliefRoute welcome screen', (tester) async {
    final auth = MockFirebaseAuth();
    await tester.pumpWidget(ReliefRouteApp(auth: auth));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to ReliefRoute'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email address'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
  });

  testWidgets('valid login opens the patient dashboard', (tester) async {
    final auth = MockFirebaseAuth();
    await tester.pumpWidget(ReliefRouteApp(auth: auth));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'demo@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'demo1234');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back, demo@example.com!'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
  });

  testWidgets('AuthGate opens the dashboard for an authenticated user', (
    tester,
  ) async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'test-user',
        email: 'patient@example.com',
        displayName: 'Test Patient',
      ),
    );
    await tester.pumpWidget(ReliefRouteApp(auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Test Patient!'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
  });

  testWidgets('registration requires the patient account fields', (
    tester,
  ) async {
    final auth = MockFirebaseAuth();
    await tester.pumpWidget(ReliefRouteApp(auth: auth));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create an account'));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'First name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Surname'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email address'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Confirm password'),
      findsOneWidget,
    );
  });
}
