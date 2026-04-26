import '../generated/objectbox/objectbox.g.dart';
import 'chat_message.dart';

abstract interface class ChatRepository {
  /// Returns up to [_maxMessages] messages ordered newest-first.
  /// If [since] is provided, only messages with `timestamp > since` are returned.
  List<ChatMessage> loadMessages({int? since});

  void saveMessage({required ChatMessageRoleEnum role, required String content});

  /// Removes ALL messages from the store. Irreversible.
  void clearAll();

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

  @override
  void clearAll() => _box.removeAll();

  /// Returns up to [_maxMessages] messages ordered newest-first (descending timestamp).
  @override
  List<ChatMessage> loadMessages({int? since}) {
    final builder =
        since != null
            ? _box.query(ChatMessage_.timestamp.greaterThan(since))
            : _box.query();

    final query =
        (builder..order(ChatMessage_.timestamp, flags: Order.descending))
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
