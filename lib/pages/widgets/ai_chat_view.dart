import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/gemini_api_bloc.dart';
import '../../bloc/gemini_api_state.dart';
import '../../bloc/status.dart';
import '../../features/foundation/style/sizes.dart';
import '../../gen/colors.gen.dart';
import '../../generated/l10n.dart';
import 'empty_widget.dart';
import 'input_area_widget.dart';

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



  @override
  Widget build(BuildContext context) {
    return BlocListener<GeminiApiBloc, GeminiApiState>(
      listener: (context, state) {
        if (state.status == Status.newPrompt ||
            state.status == Status.querySuccess) {
          _scrollToBottom();
        }
      },
      child: Scaffold(
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
        body: BlocBuilder<GeminiApiBloc, GeminiApiState>(
          builder: (context, state) {
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
                            return _MessageBubble(message: chatList[index]);
                          },
                        ),
                ),
                if (state.status == Status.queryLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Sizes.paddingS),
                    child: LinearProgressIndicator(
                      backgroundColor: ColorName.color00000000,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorName.colorFf673ab7,
                      ),
                    ),
                  ),
                const InputAreaWidget(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isAi = message.startsWith('AI reply: ');
    final String content = isAi
        ? message.replaceFirst('AI reply: ', '')
        : message.replaceFirst('Prompt: ', '');
    final bool isError = message.startsWith('Error: ');

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: Sizes.paddingL),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * Sizes.messageMaxWidthFactor,
        ),
        padding: const EdgeInsets.all(Sizes.paddingL),
        decoration: BoxDecoration(
          color: isAi ? ColorName.colorFfffffff : ColorName.colorFf673ab7,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Sizes.chatBubbleRadius),
            topRight: const Radius.circular(Sizes.chatBubbleRadius),
            bottomLeft: Radius.circular(isAi ? 0 : Sizes.chatBubbleRadius),
            bottomRight: Radius.circular(isAi ? Sizes.chatBubbleRadius : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: ColorName.color0d000000,
              blurRadius: Sizes.shadowBlurS,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isError)
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: ColorName.colorFff44336,
                    size: Sizes.iconS,
                  ),
                  const SizedBox(width: Sizes.paddingS),
                  Text(
                    S.current.errorLabel,
                    style: const TextStyle(
                      color: ColorName.colorFff44336,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            MarkdownBody(
              data: content,
              selectable: true,
              // ignore: deprecated_member_use
              imageBuilder: (uri, title, alt) {
                final uriStr = uri.toString();
                if (uriStr.startsWith('data:')) {
                  final commaIndex = uriStr.indexOf(',');
                  if (commaIndex != -1) {
                    final base64Str = uriStr.substring(commaIndex + 1);
                    try {
                      final bytes = base64Decode(base64Str);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(Sizes.paddingS),
                        child: Image.memory(bytes, fit: BoxFit.contain),
                      );
                    } catch (_) {}
                  }
                }
                return const SizedBox.shrink();
              },
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: TextStyle(
                      color: isAi
                          ? ColorName.colorDd000000
                          : ColorName.colorFfffffff,
                      fontSize: Sizes.textBody,
                      height: 1.5,
                    ),
                    code: TextStyle(
                      backgroundColor: isAi
                          ? ColorName.colorFfeeeeee
                          : ColorName.colorFf512da8,
                      color: isAi
                          ? ColorName.colorDd000000
                          : ColorName.colorFfffffff,
                    ),
                  ),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
