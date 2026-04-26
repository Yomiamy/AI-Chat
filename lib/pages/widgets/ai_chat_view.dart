import 'package:ai_chat/generated/assets/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/bloc.dart';
import '../../bloc/gemini_api/models/chat_entry_prefix.dart';
import '../../features/features.dart';
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

enum _MenuAction { newChat, clearChat, copyAll, about }

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
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert, color: ColorName.color8a000000),
            onSelected: (action) => _onMenuSelected(context, action),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.newChat,
                child: Row(children: [
                  const Icon(Icons.add_comment_outlined),
                  const SizedBox(width: Sizes.paddingS),
                  Text(S.current.menuNewChat),
                ]),
              ),
              PopupMenuItem(
                value: _MenuAction.clearChat,
                child: Row(children: [
                  const Icon(Icons.delete_outline),
                  const SizedBox(width: Sizes.paddingS),
                  Text(S.current.menuClearChat),
                ]),
              ),
              PopupMenuItem(
                value: _MenuAction.copyAll,
                child: Row(children: [
                  const Icon(Icons.copy_outlined),
                  const SizedBox(width: Sizes.paddingS),
                  Text(S.current.menuCopyAll),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _MenuAction.about,
                child: Row(children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: Sizes.paddingS),
                  Text(S.current.menuAbout),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<GeminiApiBloc, GeminiApiState>(
        listenWhen: (previous, cur) =>
            previous != cur &&
            (cur.status == Status.newPrompt || cur.status == Status.success),
        listener: (_, _) => _scrollToBottom(),
        buildWhen: (prev, cur) => prev != cur,
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

  void _onMenuSelected(BuildContext context, _MenuAction action) {
    switch (action) {
      case _MenuAction.newChat:
        context.read<GeminiApiBloc>().add(GeminiApiNewChatEvent());
      case _MenuAction.clearChat:
        _confirmClearChat(context);
      case _MenuAction.copyAll:
        _copyAllMessages(context);
      case _MenuAction.about:
        _showAboutDialog(context);
    }
  }

  void _confirmClearChat(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.current.clearChatTitle),
        content: Text(S.current.clearChatContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(S.current.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<GeminiApiBloc>().add(GeminiApiClearAllEvent());
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.current.clearChatConfirm),
          ),
        ],
      ),
    );
  }

  void _copyAllMessages(BuildContext context) {
    final state = context.read<GeminiApiBloc>().state;
    final chatList = state.chatList ?? const <String>[];

    final buffer = StringBuffer();
    // chatList 為 newest-first，reversed 才是時間順序
    for (final entry in chatList.reversed) {
      final prefix = ChatEntryPrefix.of(entry);
      final readable = switch (prefix) {
        ChatEntryPrefix.prompt => '👤 You: ${ChatEntryPrefix.prompt.strip(entry)}',
        ChatEntryPrefix.aiReply =>
          '🤖 Gemini: ${ChatEntryPrefix.aiReply.strip(entry)}',
        ChatEntryPrefix.error => '⚠️ Error: ${ChatEntryPrefix.error.strip(entry)}',
        _ => entry,
      };
      buffer.writeln(readable);
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.current.copiedToClipboard)),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: S.current.appTitle,
      applicationVersion: S.current.aboutDialogVersion(
        AppConstants.appVersion,
        AppConstants.buildNumber,
      ),
      applicationIcon: const CircleAvatar(
        backgroundColor: ColorName.colorFf673ab7,
        child: Icon(Icons.auto_awesome, color: ColorName.colorFfffffff),
      ),
      children: [
        const SizedBox(height: Sizes.paddingM),
        Text(S.current.aboutDialogModel(AppConstants.aiModel)),
        const SizedBox(height: Sizes.paddingS),
        Text(AppConstants.aiProvider),
      ],
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
