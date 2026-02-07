import 'dart:async';
import 'dart:convert';

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

    _chatList.insert(0, "Prompt: $prompt");
    emit(state.copyWith(status: Status.newPrompt, chatList: _chatList));

    emit(state.copyWith(status: Status.queryLoading));

    try {
      final response = _aiModel.generateContentStream([
        Content.text("""
        $prompt 
        請用以下格式要求回答:
        - 繁體中文回答 
        - 以markdown格式輸出
        - 依照內容調整縮排
        """),
      ]);

      await for (final chunk in response) {
        final parts = chunk.candidates.firstOrNull?.content.parts ?? [];
        if (parts.isNotEmpty) {
          StringBuffer markdownBuffer = StringBuffer();

          for (final part in parts) {
            if (part is TextPart) {
              markdownBuffer.writeln(part.text);
              continue;
            }

            if (part is ExecutableCodePart) {
              markdownBuffer.writeln(part.code);
              continue;
            }

            if (part is CodeExecutionResultPart) {
              markdownBuffer.writeln(part.output);
              continue;
            }

            if (part is InlineDataPart) {
              final mimeType = part.mimeType;
              final isImage = RegExp(
                r'image/(jpeg|png|webp)',
              ).hasMatch(mimeType);

              if (isImage) {
                final imageBytesBase64 = base64Encode(part.bytes);
                markdownBuffer.writeln(
                  '![image](data:$mimeType;base64,$imageBytesBase64)',
                );
                continue;
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
      _chatList.insert(0, "Error: $e"); // Optional: Show error in chat
    }
  }

  Future<void> _initFirebaseAiLogic() async {
    // Current valid model
    _aiModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text],
      ),
      // tools: [Tool.googleSearch(), Tool.codeExecution()], // Remove tools to simplify dependencies if not needed, but code execution was used
    );
  }
}
