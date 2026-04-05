import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'dart:io';

import 'package:ai_chat/data/chat_repository.dart';
import 'package:ai_chat/features/features.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import '../status.dart';

part 'gemini_api_event.dart';
part 'gemini_api_state.dart';

class GeminiApiBloc extends Bloc<GeminiApiEvent, GeminiApiState> {
  late GenerativeModel _aiModel;
  late List<String> _chatList;
  final ChatRepository _repo;

  GeminiApiBloc(this._repo) : super(const GeminiApiState()) {
    on<GeminiApiInitEvent>(_init);
    on<GeminiApiQueryEvent>(_query);
    on<GeminiApiPickFileEvent>(_pickFile);
    on<GeminiApiPickImageEvent>(_pickImage);
    on<GeminiApiRemoveFileEvent>(_removeFile);

    add(GeminiApiInitEvent());
  }

  void _init(GeminiApiInitEvent event, Emitter<GeminiApiState> emit) async {
    _chatList = _repo.loadMessages().map((m) {
      switch (m.role) {
        case 'prompt':
          return 'Prompt: ${m.content}';
        case 'ai_reply':
          return 'AI reply: ${m.content}';
        default:
          return 'Error: ${m.content}';
      }
    }).toList();

    await _initFirebaseAiLogic();
    emit(state.copyWith(chatList: _chatList.isEmpty ? null : _chatList));
  }

  FutureOr<void> _query(
    GeminiApiQueryEvent event,
    Emitter<GeminiApiState> emit,
  ) async {
    final prompt = event.query;
    final fileBytes = state.selectedFileBytes;
    final mimeType = state.selectedMimeType;

    // 檢查檔案大小是否超過 5MB
    if (fileBytes != null && fileBytes.lengthInBytes > 5 * 1024 * 1024) {
      _chatList.insert(0, 'Prompt: $prompt\n\n[附件被拒絕：檔案大小超過 5MB 限制]');
      _chatList.insert(0, 'Error: 上傳檔案大小不得超過 5MB');
      _repo.saveMessage(role: 'error', content: '上傳檔案大小不得超過 5MB');
      emit(state.copyWith(status: Status.failure, chatList: _chatList));
      return;
    }

    final userMessage = _buildUserMessage(prompt, fileBytes, mimeType);
    _chatList.insert(0, 'Prompt: $userMessage');

    // ① 使用者送出後寫入快取（base64 圖片替換為佔位符）
    _repo.saveMessage(role: 'prompt', content: _stripBase64(userMessage));

    emit(state.copyWith(status: Status.newPrompt, chatList: _chatList));

    try {
      emit(state.copyWith(status: Status.loading));

      final content = _buildContent(prompt, fileBytes, mimeType);
      final response = _aiModel.generateContentStream([content]);

      await for (final chunk in response) {
        final parts = chunk.candidates.firstOrNull?.content.parts ?? [];
        if (parts.isNotEmpty) {
          final markdownBuffer = StringBuffer();

          for (final part in parts) {
            if (part is TextPart) {
              markdownBuffer.writeln(part.text);
            } else if (part is ExecutableCodePart) {
              markdownBuffer.writeln(part.code);
            } else if (part is CodeExecutionResultPart) {
              markdownBuffer.writeln(part.output);
            } else if (part is InlineDataPart) {
              final mime = part.mimeType;
              if (RegExp(r'image/(jpeg|png|webp)').hasMatch(mime)) {
                final b64 = base64Encode(part.bytes);
                markdownBuffer.writeln('![image](data:$mime;base64,$b64)');
              }
            }
          }

          if (markdownBuffer.isNotEmpty) {
            final aiReply = StringBuffer();
            if (_chatList.firstOrNull?.startsWith('AI reply: ') ?? false) {
              aiReply
                ..write(_chatList.removeAt(0))
                ..write(' ${markdownBuffer.toString()}');
            } else {
              aiReply.write('AI reply: ${markdownBuffer.toString()}');
            }
            _chatList.insert(0, aiReply.toString());
          }

          _removeFile(GeminiApiRemoveFileEvent(), emit);
          emit(state.copyWith(status: Status.loading, chatList: _chatList));
        }
      }

      // ② stream 全數完成後寫入 AI 回覆
      _repo.saveMessage(
        role: 'ai_reply',
        content: _stripContent(_chatList.first),
      );
      emit(state.copyWith(status: Status.success, chatList: _chatList));
    } catch (e) {
      // ③ 錯誤時寫入快取
      _repo.saveMessage(role: 'error', content: e.toString());
      emit(state.copyWith(status: Status.failure));
      _chatList.insert(0, 'Error: $e');
    }
  }

  FutureOr<void> _pickFile(
    GeminiApiPickFileEvent event,
    Emitter<GeminiApiState> emit,
  ) async {
    final result = await FilePickManager.pickFile();

    if (result == null || result.files.isEmpty) {
      emit(state.copyWith(status: Status.failure, clearFile: true));
      return;
    }

    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && !file.path.isNullOrBlank) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) return;

    emit(
      state.copyWith(selectedFileBytes: bytes, selectedMimeType: file.mimeType),
    );
  }

  FutureOr<void> _pickImage(
    GeminiApiPickImageEvent event,
    Emitter<GeminiApiState> emit,
  ) async {
    final file = await FilePickManager.pickImageWithPermission(
      onPermissionDenied: event.onPermissionDenied,
    );

    if (file == null) {
      emit(state.copyWith(status: Status.failure, clearFile: true));
      return;
    }

    final bytes = await file.readAsBytes();
    emit(
      state.copyWith(selectedFileBytes: bytes, selectedMimeType: file.mimeType),
    );
  }

  void _removeFile(
    GeminiApiRemoveFileEvent event,
    Emitter<GeminiApiState> emit,
  ) {
    emit(state.copyWith(clearFile: true));
  }

  Future<void> _initFirebaseAiLogic() async {
    _aiModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseModalities: [
          ResponseModalities.text,
        ],
      ),
    );
  }

  String _buildUserMessage(
    String prompt,
    Uint8List? fileBytes,
    String? mimeType,
  ) {
    if (fileBytes == null || mimeType == null) return prompt;

    if (mimeType.startsWith('image/')) {
      final b64 = base64Encode(fileBytes);
      return '![img](data:$mimeType;base64,$b64)\n\n$prompt';
    } else {
      final mbSize = (fileBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2);
      return '[附件: $mimeType, 大小: $mbSize MB]\n\n$prompt';
    }
  }

  Content _buildContent(
    String prompt,
    Uint8List? imageBytes,
    String? mimeType,
  ) {
    if (imageBytes == null || mimeType == null) {
      return Content.text('''
$prompt
請用以下格式要求回答:
- 繁體中文回答
- 以markdown格式輸出
- 依照內容調整縮排
''');
    }

    return Content.multi([
      InlineDataPart(mimeType, imageBytes),
      TextPart('''
$prompt
請用以下格式要求回答:
- 繁體中文回答
- 以markdown格式輸出
- 依照內容調整縮排
'''),
    ]);
  }

  static final _base64ImagePattern = RegExp(
    r'!\[.*?\]\(data:(image/[^;]+);base64,([A-Za-z0-9+/=]+)\)',
  );

  String _stripBase64(String text) {
    return text.replaceAllMapped(_base64ImagePattern, (m) {
      final mime = m.group(1)!;
      final bytes = (m.group(2)!.length * 3 / 4).round();
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
      return '[附件: $mime, 大小: $mb MB]';
    });
  }

  String _stripAiBase64(String text) {
    return text.replaceAll(_base64ImagePattern, '[圖片回覆]');
  }

  String _stripContent(String item) {
    final content = item.contains(': ') ? item.substring(item.indexOf(': ') + 2) : item;
    return _stripAiBase64(content);
  }
}
