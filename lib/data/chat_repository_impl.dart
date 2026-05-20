import '../generated/objectbox/objectbox.g.dart';
import 'chat_message.dart';
import 'chat_repository.dart';

class ObjectBoxChatRepository implements ChatRepository {
  static const int _maxMessages = 100;
  late final Store _store;
  late final Box<ChatMessage> _box;

  ObjectBoxChatRepository._();

  static Future<ChatRepository> create() async {
    final repo = ObjectBoxChatRepository._();
    repo._store = await openStore();
    repo._box = repo._store.box<ChatMessage>();
    return repo;
  }

  @override
  void dispose() => _store.close();

  @override
  void clearAll() => _box.removeAll();

  @override
  List<ChatMessage> loadMessages({int? since}) {
    final builder = since != null
        ? _box.query(ChatMessage_.timestamp.greaterThan(since))
        : _box.query();
    final query = (builder..order(ChatMessage_.timestamp, flags: Order.descending)).build()
      ..limit = _maxMessages;
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<List<ChatMessage>> searchMessages(String query) async {
    if (query.isEmpty) return [];
    final q = _box
        .query(ChatMessage_.content.contains(query, caseSensitive: false))
        .order(ChatMessage_.timestamp, flags: Order.descending)
        .build()
      ..limit = _maxMessages;
    try {
      return await q.findAsync();
    } finally {
      q.close();
    }
  }

  @override
  void saveMessage({
    required ChatMessageRoleEnum role,
    required String content,
  }) {
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
    final query = _box.query().order(ChatMessage_.timestamp).build()..limit = excess;
    try {
      _box.removeMany(query.findIds());
    } finally {
      query.close();
    }
  }
}
