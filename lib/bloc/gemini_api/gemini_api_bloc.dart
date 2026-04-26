import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'dart:io';

import 'package:ai_chat/data/data.dart';
import 'models/models.dart';
import 'package:ai_chat/features/features.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import '../status.dart';

part 'gemini_api_event.dart';
part 'gemini_api_state.dart';

class GeminiApiBloc extends Bloc<GeminiApiEvent, GeminiApiState> {
  static final _base64ImagePattern = RegExp(
    r'!\[.*?\]\(data:(image/[^;]+);base64,([A-Za-z0-9+/=]+)\)',
  );

  static const String _sessionStartKey = 'session_start_ms';

  late GenerativeModel _aiModel;
  List<String> _chatList = [];
  final ChatRepository _repo;

  GeminiApiBloc(this._repo) : super(const GeminiApiState()) {
    on<GeminiApiInitEvent>(_init);
    on<GeminiApiQueryEvent>(_query);
    on<GeminiApiPickFileEvent>(_pickFile);
    on<GeminiApiPickImageEvent>(_pickImage);
    on<GeminiApiRemoveFileEvent>(_removeFile);
    on<GeminiApiNewChatEvent>(_newChat);
    on<GeminiApiClearAllEvent>(_clearAll);

    add(GeminiApiInitEvent());
  }

  void _init(GeminiApiInitEvent event, Emitter<GeminiApiState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStartMs = prefs.getInt(_sessionStartKey);

    _chatList = _repo.loadMessages(since: sessionStartMs).map((m) {
      return switch (m.roleEnum) {
        ChatMessageRoleEnum.prompt  => ChatEntryPrefix.prompt.wrap(m.content),
        ChatMessageRoleEnum.aiReply => ChatEntryPrefix.aiReply.wrap(m.content),
        _                           => ChatEntryPrefix.error.wrap(m.content),
      };
    }).toList();

    await _initFirebaseAiLogic();
    emit(state.copyWith(chatList: _chatList.isEmpty ? null : _chatList));
  }

  Future<void> _newChat(
    GeminiApiNewChatEvent event,
    Emitter<GeminiApiState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionStartKey, DateTime.now().millisecondsSinceEpoch);
    _chatList = [];
    emit(state.copyWith(
      status: Status.initial,
      clearChat: true,
      clearFile: true,
    ));
  }

  void _clearAll(
    GeminiApiClearAllEvent event,
    Emitter<GeminiApiState> emit,
  ) {
    _repo.clearAll();
    _chatList = [];
    emit(state.copyWith(
      status: Status.initial,
      clearChat: true,
      clearFile: true,
    ));
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
      _chatList.insert(0, ChatEntryPrefix.prompt.wrap('$prompt\n\n[附件被拒絕：檔案大小超過 5MB 限制]'));
      _chatList.insert(0, ChatEntryPrefix.error.wrap('上傳檔案大小不得超過 5MB'));
      _repo.saveMessage(role: ChatMessageRoleEnum.error, content: '上傳檔案大小不得超過 5MB');
      emit(state.copyWith(status: Status.failure, chatList: _chatList));
      return;
    }

    final userMessage = _buildUserMessage(prompt, fileBytes, mimeType);
    _chatList.insert(0, ChatEntryPrefix.prompt.wrap(userMessage));

    // ① 使用者送出後寫入快取（base64 圖片替換為佔位符）
    _repo.saveMessage(role: ChatMessageRoleEnum.prompt, content: _stripBase64(userMessage));

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
            if (ChatEntryPrefix.aiReply.matches(_chatList.firstOrNull ?? '')) {
              aiReply
                ..write(_chatList.removeAt(0))
                ..write(' ${markdownBuffer.toString()}');
            } else {
              aiReply.write(ChatEntryPrefix.aiReply.wrap(markdownBuffer.toString()));
            }
            _chatList.insert(0, aiReply.toString());
          }

          _removeFile(GeminiApiRemoveFileEvent(), emit);
          emit(state.copyWith(status: Status.loading, chatList: _chatList));
        }
      }

      // ② stream 全數完成後寫入 AI 回覆（Gemini 空回覆時略過）
      if (_chatList.isNotEmpty && ChatEntryPrefix.aiReply.matches(_chatList.first)) {
        _repo.saveMessage(
          role: ChatMessageRoleEnum.aiReply,
          content: _stripContent(_chatList.first),
        );
      }
      emit(state.copyWith(status: Status.success, chatList: _chatList));
    } catch (e) {
      // ③ 錯誤時寫入快取
      _repo.saveMessage(role: ChatMessageRoleEnum.error, content: e.toString());
      emit(state.copyWith(status: Status.failure));
      _chatList.insert(0, ChatEntryPrefix.error.wrap('$e'));
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

  String _stripContent(String item) =>
      _stripAiBase64(ChatEntryPrefix.aiReply.strip(item));
}
