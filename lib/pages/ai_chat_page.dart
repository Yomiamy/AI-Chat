import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/gemini_api/gemini_api_bloc.dart';
import '../data/data.dart';
import '../features/utils/widget_preview.dart';
import 'widgets/ai_chat_view.dart';

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GeminiApiBloc(GetIt.I<ChatRepository>()),
      child: const AiChatView(),
    );
  }
}

@DevicePreviewAll()
Widget previewPage() => const AiChatPage();
