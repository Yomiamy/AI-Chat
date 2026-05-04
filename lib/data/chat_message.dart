import 'package:objectbox/objectbox.dart';
import 'package:collection/collection.dart';

@Entity()
class ChatMessage {
  @Id()
  int id = 0;

  String content;
  int timestamp;
  String role; // stored value — use roleEnum for type-safe access

  @Transient()
  ChatMessageRoleEnum? get roleEnum => ChatMessageRoleEnum.fromValue(role);

  ChatMessage({
    this.id = 0,
    required this.content,
    required this.timestamp,
    required this.role,
  });
}

enum ChatMessageRoleEnum {
  prompt('prompt'),
  aiReply('ai_reply'),
  error('error');

  final String value;

  const ChatMessageRoleEnum(this.value);

  static ChatMessageRoleEnum? fromValue(String value) {
    return ChatMessageRoleEnum.values.firstWhereOrNull((e) => e.value == value);
  }
}
