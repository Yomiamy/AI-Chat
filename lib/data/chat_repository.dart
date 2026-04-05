import '../generated/objectbox/objectbox.g.dart';
import 'chat_message.dart';

class ChatRepository {
  final Store _store;
  final Box<ChatMessage> _box;

  ChatRepository(Store store)
      : _store = store,
        _box = store.box<ChatMessage>();

  void dispose() => _store.close();

  /// Returns up to 100 messages ordered newest-first (descending timestamp).
  List<ChatMessage> loadMessages() {
    final query = _box
        .query()
        .order(ChatMessage_.timestamp, flags: Order.descending)
        .build()
      ..limit = 100;
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  void saveMessage({required String role, required String content}) {
    _box.put(ChatMessage(
      content: content,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      role: role,
    ));
    _trimToLimit();
  }

  void _trimToLimit() {
    const limit = 100;
    final count = _box.count();
    if (count > limit) {
      final query = _box
          .query()
          .order(ChatMessage_.timestamp)
          .build()
        ..limit = 1;
      try {
        final oldest = query.findFirst();
        if (oldest != null) _box.remove(oldest.id);
      } finally {
        query.close();
      }
    }
  }
}
