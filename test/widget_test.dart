// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:giftgame/main.dart';
import 'package:giftgame/providers/game_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app wrapped with the same providers as main
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GameProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // The original template expects a counter starting at 0, but our app doesn't expose that.
    // Adjust expectation: ensure the app builds by finding the title text.
    expect(find.text('Gift Game'), findsOneWidget);
  });
}
