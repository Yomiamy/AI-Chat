import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat/services/export_service.dart';
import 'package:ai_chat/data/chat_message.dart';
import 'package:ai_chat/generated/l10n.dart';
import 'package:flutter/material.dart';

void main() {
  late ExportService exportService;

  setUpAll(() async {
    // Initialize localization for tests
    await S.load(const Locale('en'));
  });

  setUp(() {
    exportService = ExportService();
  });

  final mockMessages = [
    ChatMessage(
      content: 'Hello AI',
      timestamp: 1625097600000, // 2021-07-01
      role: ChatMessageRoleEnum.prompt.value,
    ),
    ChatMessage(
      content: 'Hello human',
      timestamp: 1625097660000,
      role: ChatMessageRoleEnum.aiReply.value,
    ),
  ];

  test('formatAsTxt should contain correct roles and content', () {
    final result = exportService.formatAsTxt(mockMessages);
    expect(result, contains('[You]'));
    expect(result, contains('Hello AI'));
    expect(result, contains('[AI]'));
    expect(result, contains('Hello human'));
  });

  test('formatAsMarkdown should contain markdown headers and bold roles', () {
    final result = exportService.formatAsMarkdown(mockMessages);
    expect(result, startsWith('# AI Chat'));
    expect(result, contains('**You**'));
    expect(result, contains('**AI**'));
    expect(result, contains('---'));
  });

  test('generateFilename should include timestamp and extension', () {
    final filename = exportService.generateFilename('txt');
    expect(filename, startsWith('chat_export_'));
    expect(filename, endsWith('.txt'));
  });
}
