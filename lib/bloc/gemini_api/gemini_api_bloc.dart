import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'dart:io';

import 'package:ai_chat/features/features.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../status.dart';

part 'gemini_api_event.dart';
part 'gemini_api_state.dart';

class GeminiApiBloc extends Bloc<GeminiApiEvent, GeminiApiState> {
  late GenerativeModel _aiModel;
  late List<String> _chatList;

  GeminiApiBloc() : super(const GeminiApiState()) {
    on<GeminiApiInitEvent>(_init);
    on<GeminiApiQueryEvent>(_query);
    on<GeminiApiPickFileEvent>(_pickFile);
    on<GeminiApiPickImageEvent>(_pickImage);
    on<GeminiApiRemoveFileEvent>(_removeFile);

    add(GeminiApiInitEvent());
  }

  void _init(GeminiApiInitEvent event, Emitter<GeminiApiState> emit) async {
    _chatList = [];
    await _initFirebaseAiLogic();

    emit(const GeminiApiState());
  }

  FutureOr<void> _query(
    GeminiApiQueryEvent event,
    Emitter<GeminiApiState> emit,
  ) async {
    final prompt = event.query;
    final fileBytes = state.selectedFileBytes;
    final mimeType = state.selectedMimeType;

    // 檢查檔案大小是否超過 5MB (5 * 1024 * 1024 bytes)
    if (fileBytes != null && fileBytes.lengthInBytes > 5 * 1024 * 1024) {
      _chatList.insert(0, 'Prompt: $prompt\n\n[附件被拒絕：檔案大小超過 5MB 限制]');
      _chatList.insert(0, 'Error: 上傳檔案大小不得超過 5MB');
      emit(state.copyWith(status: Status.failure, chatList: _chatList));
      return;
    }

    // 組裝使用者訊息（可能包含檔案資訊或圖片的 base64 markdown）
    final userMessage = _buildUserMessage(prompt, fileBytes, mimeType);
    _chatList.insert(0, 'Prompt: $userMessage');
    emit(state.copyWith(status: Status.newPrompt, chatList: _chatList));

    // 組裝AI回覆訊息
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

          // 清除選取好的檔案，因為已經開始送出了
          _removeFile(GeminiApiRemoveFileEvent(), emit);
          emit(state.copyWith(status: Status.loading, chatList: _chatList));
        }
      }
      emit(state.copyWith(status: Status.success, chatList: _chatList));
    } catch (e) {
      emit(state.copyWith(status: Status.failure));
      _chatList.insert(0, 'Error: $e');
    }
  }

  FutureOr<void> _pickFile(
    GeminiApiPickFileEvent event,
    Emitter<GeminiApiState> emit,
  ) async {
    final result = await PermissionManager.pickFile();

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    // 有緩存就先用緩存
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
    final file = await PermissionManager.pickImageWithPermission(event.context);

    if (file == null) return;

    final bytes = await file.readAsBytes();
    emit(
      state.copyWith(selectedFileBytes: bytes, selectedMimeType: file.mimeType),
    );
  }

  void _removeFile(
    GeminiApiRemoveFileEvent event,
    Emitter<GeminiApiState> emit,
  ) {
    emit(state.copyWith(selectedFileBytes: null, selectedMimeType: null));
  }

  Future<void> _initFirebaseAiLogic() async {
    // final thinkingConfig = ThinkingConfig.withThinkingBudget(2000, includeThoughts: true,); //設定思考模型的預算（例如 2000 tokens）及 思考總結
    _aiModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        // thinkingConfig: thinkingConfig, 啟用思考功能配置
        responseModalities: [
          ResponseModalities.text,
          // 支援多模態輸出（圖片、音訊），目前為註解狀態
          // ResponseModalities.image,
          // ResponseModalities.audio,
        ],
      ),
    );
  }

  /// 組裝使用者在氣泡中顯示的訊息字串（圖片以 base64 markdown 嵌入，其他檔案顯示檔名或類型與大小）
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
      final mbSize = (fileBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(
        2,
      );
      return '[附件: $mimeType, 大小: $mbSize MB]\n\n$prompt';
    }
  }

  /// 組裝送給 Gemini 的 Content（有圖片用 multi，無圖片用 text）
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
}
