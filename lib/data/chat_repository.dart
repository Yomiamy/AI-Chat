import '../generated/objectbox/objectbox.g.dart';
import 'chat_message.dart';

abstract interface class ChatRepository {
  List<ChatMessage> loadMessages();
  void saveMessage({required ChatMessageRoleEnum role, required String content});
  void dispose();
}

class ChatRepo implements ChatRepository {
  static const int _maxMessages = 100;

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

  /// Returns up to [_maxMessages] messages ordered newest-first (descending timestamp).
  @override
  List<ChatMessage> loadMessages() {
    final query =
        _box
            .query()
            .order(ChatMessage_.timestamp, flags: Order.descending)
            .build()
          ..limit = _maxMessages;
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
    final count = _box.count();
    final excess = count - _maxMessages;
    if (excess <= 0) return;
    final query = _box.query().order(ChatMessage_.timestamp).build()
      ..limit = excess;
    try {
      _box.removeMany(query.findIds());
    } finally {
      query.close();
    }
  }
}
