import 'package:ai_chat/pages/widgets/search_app_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_chat/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('appbar test', () {
    testWidgets('tapping search icon shows SearchAppBar', (
      WidgetTester tester,
    ) async {
      // main() 是 async（內含 Firebase.initializeApp 等 await），必須 await。
      await app.main();
      // 不用 pumpAndSettle：chat 初始狀態有 CircularProgressIndicator（無限動畫），
      // 永遠 settle 不了。改用固定時長 pump 推進初始 frame。
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      // _isSearching 由 setState 同步切換，pump 一幀即可完成 AppBar 替換。
      await tester.pump();

      expect(find.byType(SearchAppBar), findsOneWidget);
    });
  });
}
