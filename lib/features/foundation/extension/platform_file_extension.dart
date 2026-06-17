import 'package:file_selector/file_selector.dart';

extension XFileMimeTypeX on XFile {
  String get mimeType {
    final dotIndex = name.lastIndexOf('.');
    final ext = dotIndex == -1 ? '' : name.substring(dotIndex + 1).toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      'doc' || 'docx' => 'application/msword',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}
