import '../generated/objectbox/objectbox.g.dart';
import 'chat_message.dart';

class ChatRepository {
  final Store _store;
  final Box<ChatMessage> _box;

  ChatRepository(Store store)
      : _store = store,
        _box = store.box<ChatMessage>();

  void dispose() => _store.close();

  List<ChatMessage> loadMessages() {
    return _box
        .query()
        .order(ChatMessage_.timestamp, flags: Order.descending)
        .build()
        .find()
        .take(100)
        .toList();
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
      final oldest = _box
          .query()
          .order(ChatMessage_.timestamp)
          .build()
          .findFirst();
      if (oldest != null) _box.remove(oldest.id);
    }
  }
}
