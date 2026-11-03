import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:reliefroute/main.dart';

void main() {
  testWidgets('shows the ReliefRoute welcome screen', (tester) async {
    await tester.pumpWidget(const ReliefRouteApp());
    expect(find.text('Welcome to ReliefRoute'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('valid login opens the patient dashboard', (tester) async {
    await tester.pumpWidget(const ReliefRouteApp());
    await tester.enterText(find.byType(TextFormField).first, 'Demo Patient');
    await tester.enterText(find.byType(TextFormField).last, 'demo1234');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back, Demo Patient!'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
  });
}
