import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'status.dart';

import 'gemini_api_event.dart';
import 'gemini_api_state.dart';

class GeminiApiBloc extends Bloc<GeminiApiEvent, GeminiApiState> {
  late GenerativeModel _aiModel;
  late List<String> _chatList;

  GeminiApiBloc() : super(const GeminiApiState()) {
    on<InitEvent>(_init);
    on<QueryEvent>(_query);

    add(InitEvent());
  }

  void _init(InitEvent event, Emitter<GeminiApiState> emit) async {
    _chatList = [];
    await _initFirebaseAiLogic();

    emit(const GeminiApiState());
  }

  FutureOr<void> _query(QueryEvent event, Emitter<GeminiApiState> emit) async {
    final prompt = event.query;
    final imageBytes = event.imageBytes;
    final mimeType = event.mimeType;

    // 檢查檔案大小是否超過 5MB (5 * 1024 * 1024 bytes)
    if (imageBytes != null && imageBytes.lengthInBytes > 5 * 1024 * 1024) {
      _chatList.insert(0, 'Prompt: $prompt\n\n[附件被拒絕：檔案大小超過 5MB 限制]');
      _chatList.insert(0, 'Error: 上傳檔案大小不得超過 5MB');
      emit(state.copyWith(status: Status.queryFailure, chatList: _chatList));
      return;
    }

    // 組裝使用者訊息（可能包含檔案資訊或圖片的 base64 markdown）
    final userMessage = _buildUserMessage(prompt, imageBytes, mimeType);
    _chatList.insert(0, 'Prompt: $userMessage');
    emit(state.copyWith(status: Status.newPrompt, chatList: _chatList));
    emit(state.copyWith(status: Status.queryLoading));

    try {
      final content = _buildContent(prompt, imageBytes, mimeType);
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

          emit(
            state.copyWith(status: Status.querySuccess, chatList: _chatList),
          );
        }
      }
    } catch (e) {
      emit(state.copyWith(status: Status.queryFailure));
      _chatList.insert(0, 'Error: $e');
    }
  }

  /// 組裝使用者在氣泡中顯示的訊息字串（圖片以 base64 markdown 嵌入，其他檔案顯示檔名或類型與大小）
  String _buildUserMessage(
    String prompt,
    Uint8List? imageBytes,
    String? mimeType,
  ) {
    if (imageBytes == null || mimeType == null) return prompt;
    
    if (mimeType.startsWith('image/')) {
      final b64 = base64Encode(imageBytes);
      return '![img](data:$mimeType;base64,$b64)\n\n$prompt';
    } else {
      final mbSize = (imageBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2);
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

  Future<void> _initFirebaseAiLogic() async {
    _aiModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text],
      ),
    );
  }
}
