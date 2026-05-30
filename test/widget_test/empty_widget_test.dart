import 'dart:ui' as ui;
import 'package:ai_chat/generated/l10n.dart';
import 'package:ai_chat/pages/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await S.load(ui.PlatformDispatcher.instance.locale);
  });

  group('EmptyWidget_Test, title and hint test', () {
    testWidgets('test empty title and message', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: EmptyWidget())));

      expect(find.text(S.current.howCanIHelp), findsOneWidget);
      expect(find.text(S.current.howCanIHelp), findsOneWidget);
    });

    testWidgets('test empty icon', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: EmptyWidget())));

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });
  });
}
