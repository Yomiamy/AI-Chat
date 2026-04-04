import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/bloc.dart';
import '../../features/foundation/style/sizes.dart';
import '../../gen/colors.gen.dart';
import '../../generated/l10n.dart';
import 'empty_widget.dart';
import 'input_area_widget.dart';
import 'loading_indicator_widget.dart';
import 'message_bubble_widget.dart';

class AiChatView extends StatefulWidget {
  const AiChatView({super.key});

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorFff5f7fb,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ColorName.colorFfffffff,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: ColorName.colorFf673ab7,
              child: Icon(
                Icons.auto_awesome,
                color: ColorName.colorFfffffff,
                size: Sizes.chatHeaderIconSize,
              ),
            ),
            const SizedBox(width: Sizes.paddingM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.current.aiAssistantTitle,
                  style: const TextStyle(
                    color: ColorName.colorDd000000,
                    fontSize: Sizes.textL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  S.current.onlineStatus,
                  style: const TextStyle(
                    color: ColorName.colorFf4caf50,
                    fontSize: Sizes.textS,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: ColorName.color8a000000),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocConsumer<GeminiApiBloc, GeminiApiState>(
        listenWhen: (previous, cur) =>
            previous != cur &&
            (cur.status == Status.newPrompt || cur.status == Status.success),
        listener: (_, _) => _scrollToBottom(),
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (_, state) {
          final chatList = state.chatList ?? [];
          return Column(
            children: [
              Expanded(
                child: chatList.isEmpty
                    ? const EmptyWidget()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Sizes.paddingL,
                          vertical: Sizes.listPaddingV,
                        ),
                        reverse: true,
                        itemCount: chatList.length,
                        itemBuilder: (context, index) {
                          return MessageBubbleWidget(message: chatList[index]);
                        },
                      ),
              ),
              if (state.status == Status.loading)
                const LoadingIndicatorWidget(),
              const InputAreaWidget(),
            ],
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
