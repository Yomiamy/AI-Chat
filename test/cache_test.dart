// Tests for logic that does NOT depend on the ObjectBox native library.
//
// ChatRepository requires libobjectbox.dylib which is only available when
// running on-device or in an integration-test environment.  Those tests live
// in integration_test/chat_repository_test.dart instead.
//
// This file pins the pure-Dart behaviour of the base64 / prefix-strip helpers
// that live in GeminiApiBloc.  The methods are private, so we reproduce the
// logic here to document and guard the expected contracts.

import 'package:flutter_test/flutter_test.dart';

void main() {
  // -------------------------------------------------------------------------
  // _stripBase64 — replaces Markdown base64 image with a size placeholder
  // -------------------------------------------------------------------------

  group('_stripBase64 logic (pinned contract)', () {
    // Mirrors the actual implementation in gemini_api_bloc.dart
    final base64ImagePattern = RegExp(
      r'!\[.*?\]\(data:(image/[^;]+);base64,([A-Za-z0-9+/=]+)\)',
    );

    String stripBase64(String text) {
      return text.replaceAllMapped(base64ImagePattern, (m) {
        final mime = m.group(1)!;
        final bytes = (m.group(2)!.length * 3 / 4).round();
        final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
        return '[附件: $mime, 大小: $mb MB]';
      });
    }

    test('replaces base64 image markdown with size placeholder', () {
      // A minimal valid base64 string (12 chars → 9 bytes → ~0.00 MB)
      const input = '![img](data:image/jpeg;base64,/9j/4AAQSkZJRgAB)';
      final result = stripBase64(input);
      expect(result, startsWith('[附件: image/jpeg, 大小:'));
      expect(result, isNot(contains('base64,')));
    });

    test('leaves text without base64 images unchanged', () {
      const input = 'Hello, world! No images here.';
      expect(stripBase64(input), equals(input));
    });

    test('replaces multiple base64 images in one string', () {
      const input =
          '![a](data:image/png;base64,ABC=) and ![b](data:image/jpeg;base64,DEF=)';
      final result = stripBase64(input);
      expect(result, isNot(contains('base64,')));
      expect(result.split('[附件:'), hasLength(3)); // 2 replacements + prefix
    });

    test('preserves surrounding text when replacing', () {
      const input = 'Look: ![img](data:image/png;base64,AAAA) — end';
      final result = stripBase64(input);
      expect(result, startsWith('Look: [附件:'));
      expect(result, endsWith('— end'));
    });
  });

  // -------------------------------------------------------------------------
  // _stripContent — strips "AI reply: " prefix then applies _stripAiBase64
  // -------------------------------------------------------------------------

  group('_stripContent logic (pinned contract)', () {
    final base64ImagePattern = RegExp(
      r'!\[.*?\]\(data:(image/[^;]+);base64,([A-Za-z0-9+/=]+)\)',
    );

    String stripAiBase64(String text) =>
        text.replaceAll(base64ImagePattern, '[圖片回覆]');

    String stripContent(String item) {
      const prefix = 'AI reply: ';
      final content =
          item.startsWith(prefix) ? item.substring(prefix.length) : item;
      return stripAiBase64(content);
    }

    test('strips "AI reply: " prefix', () {
      expect(stripContent('AI reply: hello world'), equals('hello world'));
    });

    test('leaves strings without the prefix unchanged', () {
      expect(stripContent('Error: something'), equals('Error: something'));
      expect(stripContent('Prompt: hi'), equals('Prompt: hi'));
      expect(stripContent('plain text'), equals('plain text'));
    });

    test('handles AI reply that itself contains ": "', () {
      expect(
        stripContent('AI reply: Explanation: some text'),
        equals('Explanation: some text'),
      );
    });

    test('does not strip partial prefix match', () {
      expect(stripContent('AI reply'), equals('AI reply'));
      expect(stripContent('AI reply:text'), equals('AI reply:text'));
    });

    test('replaces base64 images in AI reply content', () {
      final input = 'AI reply: here: ![x](data:image/png;base64,AAAA)';
      final result = stripContent(input);
      expect(result, equals('here: [圖片回覆]'));
    });
  });
}
