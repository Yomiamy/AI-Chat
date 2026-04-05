import '../generated/objectbox/objectbox.g.dart';
import 'chat_message.dart';

abstract interface class ChatRepository {
  List<ChatMessage> loadMessages();
  void saveMessage({required ChatMessageRoleEnum role, required String content});
  void dispose();
}

class ChatRepo implements ChatRepository {
  late final Store _store;
  late final Box<ChatMessage> _box;

  ChatRepo._();

  static Future<ChatRepository> create() async {
    final repo = ChatRepo._();
    repo._store = await openStore();
    repo._box = repo._store.box<ChatMessage>();

    return repo;
  }

  @override
  void dispose() => _store.close();

  /// Returns up to 100 messages ordered newest-first (descending timestamp).
  @override
  List<ChatMessage> loadMessages() {
    final query =
        _box
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

  @override
  void saveMessage({required ChatMessageRoleEnum role, required String content}) {
    _box.put(
      ChatMessage(
        content: content,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        role: role.value,
      ),
    );
    _trimToLimit();
  }

  void _trimToLimit() {
    const limit = 100;
    final count = _box.count();
    if (count > limit) {
      final query = _box.query().order(ChatMessage_.timestamp).build()
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
