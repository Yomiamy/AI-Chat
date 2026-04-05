import 'package:objectbox/objectbox.dart';

@Entity()
class ChatMessage {
  @Id()
  int id = 0;

  String content;
  int timestamp;
  String role; // "prompt" | "ai_reply" | "error"

  ChatMessage({
    this.id = 0,
    required this.content,
    required this.timestamp,
    required this.role,
  });
}
