import 'package:file_picker/file_picker.dart';

extension PlatformFileX on PlatformFile {
  String get mimeType {
    final ext = extension?.toLowerCase() ?? '';
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
