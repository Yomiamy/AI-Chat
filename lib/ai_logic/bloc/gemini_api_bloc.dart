import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:firebase_ai/firebase_ai.dart';

import 'status.dart';
import 'gemini_api_event.dart';
import 'gemini_api_state.dart';

class GeminiApiBloc extends Bloc<GeminiApiEvent, GeminiApiState> {
  late GenerativeModel _aiModel;
  // late ImagenModel _imagenModel; // Commented out in source
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
      /** Handle the normal model response **/
      final parts = chunk.candidates.firstOrNull?.content.parts ?? [];
      if (parts.isNotEmpty) {
        StringBuffer markdownBuffer = StringBuffer();

        for (final part in parts) {
          if (part is TextPart) {
            markdownBuffer.writeln(part.text);
            continue;
          }

          /// Execute code part
          if (part is ExecutableCodePart) {
            markdownBuffer.writeln(part.code);
            continue;
          }

          /// Execute code result part
          if (part is CodeExecutionResultPart) {
            markdownBuffer.writeln(part.output);
            continue;
          }

          if (part is InlineDataPart) {
            // Use regular expression to check for image mime types
            final mimeType = part.mimeType;
            final isImage = RegExp(r'image/(jpeg|png|webp)').hasMatch(mimeType);
            final isFile = RegExp(r'application/pdf').hasMatch(mimeType);
            // final isAudio = RegExp(r'audio/(mpeg)').hasMatch(mimeType); // Unused

            if (isImage) {
              // Process image output
              final imageBytesBase64 = base64Encode(part.bytes);
              markdownBuffer.writeln(
                '![image](data:$mimeType;base64,$imageBytesBase64)',
              );
              continue;
            }

            if (isFile) {
              // Process file output
              continue;
            }
          }
        }

        if (markdownBuffer.isNotEmpty) {
          final aiReply = StringBuffer();

          if (_chatList.firstOrNull?.startsWith('AI reply: ') ?? false) {
            // Remove the previous AI reply if it exists
            aiReply
              ..write(_chatList.removeAt(0))
              ..write(' ${markdownBuffer.toString()}');
          } else {
            aiReply.write('AI reply: ${markdownBuffer.toString()}');
          }
          _chatList.insert(0, aiReply.toString());
        }
        emit(state.copyWith(status: Status.querySuccess, chatList: _chatList));
      }
    }
  }

  Future<void> _initFirebaseAiLogic() async {
    /** [Gemini text model] */
    _aiModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text],
      ),
      tools: [Tool.googleSearch(), Tool.codeExecution()],
    );
  }
}
