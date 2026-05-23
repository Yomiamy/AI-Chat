import 'chat_message.dart';

abstract interface class ChatRepository {
  /// Returns up to the maximum allowed messages ordered newest-first.
  /// If [since] is provided, only messages with `timestamp > since` are returned.
  List<ChatMessage> loadMessages({int? since});

  void saveMessage({
    required ChatMessageRoleEnum role,
    required String content,
  });

  /// Removes ALL messages from the store. Irreversible.
  void clearAll();

  Future<List<ChatMessage>> searchMessages(String query);

  void dispose();
}
