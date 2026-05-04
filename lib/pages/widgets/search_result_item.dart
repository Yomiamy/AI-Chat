import 'package:flutter/material.dart';
import '../../data/chat_message.dart';
import 'highlight_text.dart';

class SearchResultItem extends StatelessWidget {
  final ChatMessage message;
  final String query;
  final VoidCallback? onTap;

  const SearchResultItem({
    super.key,
    required this.message,
    required this.query,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    final timeStr =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final isAi = message.roleEnum == ChatMessageRoleEnum.aiReply;
    final roleLabel = isAi ? 'AI' : 'You';

    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Text(
            roleLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isAi ? Colors.blue : Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: HighlightText(
          text: message.content,
          highlight: query,
          style: const TextStyle(fontSize: 14, color: Colors.black),
          highlightStyle: TextStyle(
            backgroundColor: Colors.yellow.withValues(alpha: 0.5),
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
