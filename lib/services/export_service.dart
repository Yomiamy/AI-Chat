import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/chat_message.dart';
import '../generated/l10n.dart';

class ExportService {
  String formatAsTxt(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln(S.current.appTitle);
    buffer.writeln('Export Time: ${DateTime.now()}');
    buffer.writeln('==================\n');

    for (final msg in messages.reversed) {
      final date = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
      final role = msg.roleEnum == ChatMessageRoleEnum.aiReply ? 'AI' : 'You';
      buffer.writeln('[$role] $date');
      buffer.writeln('${msg.content}\n');
    }
    return buffer.toString();
  }

  String formatAsMarkdown(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln('# ${S.current.appTitle}\n');
    buffer.writeln('> Export Time: ${DateTime.now()}\n');
    buffer.writeln('---\n');

    for (final msg in messages.reversed) {
      final date = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
      final role = msg.roleEnum == ChatMessageRoleEnum.aiReply ? 'AI' : 'You';
      buffer.writeln('**$role** *$date*\n');
      buffer.writeln('${msg.content}\n');
      buffer.writeln('---\n');
    }
    return buffer.toString();
  }

  Future<void> shareAsFile({
    required String content,
    required String filename,
    String? subject,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(content);

    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }

  String generateFilename(String ext) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'chat_export_$timestamp.$ext';
  }
}
