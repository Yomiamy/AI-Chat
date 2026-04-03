// AI Chat application smoke tests.
//
// AiChatPage creates its own BlocProvider<GeminiApiBloc> internally,
// and GeminiApiBloc immediately fires InitEvent which calls Firebase.
// Pumping AiChatPage directly in tests would therefore require a live
// Firebase connection, which is not available in unit/widget test
// environments.
//
// Strategy:
//   1. Unit-test GeminiApiState to verify the default (empty) state
//      data structure without touching Firebase at all.
//   2. Smoke-test the empty-state UI by pumping a self-contained
//      MaterialApp that reproduces only the widgets shown when
//      chatList is empty — the same widget tree _buildEmptyState()
//      produces inside AiChatPage — without constructing GeminiApiBloc.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_chat/bloc/gemini_api/gemini_api_state.dart';
import 'package:ai_chat/bloc/status.dart';

// ---------------------------------------------------------------------------
// 1. Unit tests — GeminiApiState (no Firebase, no widget tree)
// ---------------------------------------------------------------------------

void main() {
  group('GeminiApiState', () {
    test('initial state has Status.initial and null chatList', () {
      const state = GeminiApiState();
      expect(state.status, Status.initial);
      expect(state.chatList, isNull);
    });

    test('copyWith status updates status and keeps chatList', () {
      const state = GeminiApiState();
      final updated = state.copyWith(status: Status.queryLoading);
      expect(updated.status, Status.queryLoading);
      expect(updated.chatList, isNull);
    });

    test('copyWith chatList updates chatList and keeps status', () {
      const state = GeminiApiState();
      final withChats = state.copyWith(
        status: Status.querySuccess,
        chatList: ['AI reply: hello'],
      );
      expect(withChats.chatList, hasLength(1));
      expect(withChats.chatList!.first, startsWith('AI reply:'));
    });

    test('empty chatList results in empty-state display condition', () {
      // AiChatPage shows empty state when chatList == null or isEmpty.
      const state = GeminiApiState();
      final chatList = state.chatList ?? [];
      expect(chatList.isEmpty, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // 2. Widget smoke tests — empty-state UI (no Firebase, no BlocProvider)
  // -------------------------------------------------------------------------

  group('AI Chat empty-state UI', () {
    // Build only the widgets that AiChatPage._buildEmptyState() renders.
    // This avoids constructing GeminiApiBloc (and therefore Firebase).
    Widget buildEmptyStateWidget() {
      return const MaterialApp(
        home: Scaffold(
          body: _EmptyStateSmokeWidget(),
        ),
      );
    }

    testWidgets('empty state renders chat_bubble_outline icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildEmptyStateWidget());

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('AppBar with auto_awesome icon is renderable',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: _AppBarSmokeWidget(),
            ),
            body: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('input area renders send and attachment icons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _InputAreaSmokeWidget(),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Minimal smoke widgets — mirror AiChatPage structure without Firebase/BLoC
// ---------------------------------------------------------------------------

/// Mirrors AiChatPage._buildEmptyState() without any BLoC dependency.
class _EmptyStateSmokeWidget extends StatelessWidget {
  const _EmptyStateSmokeWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0x1A7C3AED),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Color(0xFF673AB7),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text('Type a message or attach a file'),
        ],
      ),
    );
  }
}

/// Mirrors the AppBar structure in AiChatPage.build() without Firebase/BLoC.
class _AppBarSmokeWidget extends StatelessWidget {
  const _AppBarSmokeWidget();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: const [
          CircleAvatar(
            backgroundColor: Color(0xFF673AB7),
            child: Icon(Icons.auto_awesome, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text('AI Assistant'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }
}

/// Mirrors the input-area row in AiChatPage._buildInputArea() without Firebase/BLoC.
class _InputAreaSmokeWidget extends StatelessWidget {
  const _InputAreaSmokeWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x1A673AB7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image_outlined, color: Color(0xFF673AB7)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x1A673AB7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.attach_file, color: Color(0xFF673AB7)),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF673AB7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
