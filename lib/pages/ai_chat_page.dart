import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/permission_manager.dart';
import '../generated/l10n.dart';

import '../bloc/gemini_api_bloc.dart';
import '../bloc/gemini_api_state.dart';
import '../bloc/gemini_api_event.dart';
import '../bloc/status.dart';
import '../features/foundation/style/sizes.dart';
import '../gen/colors.gen.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late final TextEditingController _textEditingController;
  final ScrollController _scrollController = ScrollController();

  Uint8List? _selectedImageBytes;
  String? _selectedMimeType;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
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

  Future<void> _pickImage() async {
    final file = await PermissionManager.pickImageWithPermission(context);

    if (file == null) return;

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    setState(() {
      _selectedImageBytes = bytes;
      _selectedMimeType = mime;
    });
  }

  Future<void> _pickGeneralFile() async {
    final result = await PermissionManager.pickFile();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;

    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) return;

    final ext = file.extension?.toLowerCase() ?? '';
    final mime = switch (ext) {
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      'doc' || 'docx' => 'application/msword',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };

    setState(() {
      _selectedImageBytes = bytes;
      _selectedMimeType = mime;
    });
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedMimeType = null;
    });
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
              child: Icon(Icons.auto_awesome, color: ColorName.colorFfffffff, size: Sizes.chatHeaderIconSize),
            ),
            const SizedBox(width: Sizes.paddingM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.current.aiAssistantTitle,
                  style: const TextStyle(
                    color: ColorName.colorDd000000,
                    fontSize: Sizes.paddingL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  S.current.onlineStatus,
                  style: const TextStyle(
                    color: ColorName.colorFf4caf50,
                    fontSize: Sizes.paddingM,
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
      body: BlocProvider(
        create: (context) => GeminiApiBloc(),
        child: BlocConsumer<GeminiApiBloc, GeminiApiState>(
          listener: (context, state) {
            if (state.status == Status.newPrompt ||
                state.status == Status.querySuccess) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            final chatList = state.chatList ?? [];
            return Column(
              children: [
                Expanded(
                  child: chatList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sizes.paddingL,
                            vertical: Sizes.chatBubbleRadius,
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
                _buildInputArea(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: Sizes.avatarRadius,
            backgroundColor: ColorName.color1a7c3aed,
            child: Icon(
              Icons.chat_bubble_outline,
              size: Sizes.avatarRadius,
              color: ColorName.colorFf673ab7,
            ),
          ),
          SizedBox(height: Sizes.paddingXL),
          Text(
            S.current.howCanIHelp,
            style: const TextStyle(
              fontSize: Sizes.chatBubbleRadius,
              fontWeight: FontWeight.bold,
              color: ColorName.colorDd000000,
            ),
          ),
          const SizedBox(height: Sizes.paddingM),
          Text(
            S.current.typeMessageOrAttach,
            style: const TextStyle(fontSize: Sizes.paddingL, color: ColorName.color8a000000),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Sizes.paddingL,
        Sizes.paddingS,
        Sizes.paddingL,
        Sizes.paddingXXL,
      ),
      decoration: BoxDecoration(
        color: ColorName.colorFfffffff,
        boxShadow: [
          BoxShadow(
            color: ColorName.color0d000000,
            blurRadius: Sizes.dividerS,
            offset: const Offset(0, -Sizes.paddingXS),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 檔案/圖片預覽區
          if (_selectedImageBytes != null) ...[
            _FilePreview(
              fileBytes: _selectedImageBytes!,
              mimeType: _selectedMimeType ?? 'application/octet-stream',
              onRemove: _clearSelectedImage,
            ),
            const SizedBox(height: Sizes.paddingS),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 選圖按鈕
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(Sizes.dividerS),
                  decoration: const BoxDecoration(
                    color: ColorName.color1a673ab7,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: ColorName.colorFf673ab7,
                    size: Sizes.chatActionIconSize,
                  ),
                ),
              ),
              const SizedBox(width: Sizes.paddingS),
              // 一般檔案按鈕
              GestureDetector(
                onTap: _pickGeneralFile,
                child: Container(
                  padding: const EdgeInsets.all(Sizes.dividerS),
                  decoration: const BoxDecoration(
                    color: ColorName.color1a673ab7,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.attach_file,
                    color: ColorName.colorFf673ab7,
                    size: Sizes.chatActionIconSize,
                  ),
                ),
              ),
              const SizedBox(width: Sizes.paddingS),
              // 文字輸入框
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.paddingL),
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: ColorName.colorFff0f2f6,
                    borderRadius: BorderRadius.circular(Sizes.paddingXL),
                  ),
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey ==
                                  LogicalKeyboardKey.numpadEnter) &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _sendMessage(context);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _textEditingController,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: S.current.typeMessageHint,
                        border: InputBorder.none,
                        hintStyle: const TextStyle(color: ColorName.color61000000),
                      ),
                      maxLines: null,
                      onSubmitted: (value) => _sendMessage(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Sizes.dividerS),
              // 送出按鈕
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => _sendMessage(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(Sizes.paddingM),
                    decoration: const BoxDecoration(
                      color: ColorName.colorFf673ab7,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: ColorName.colorFfffffff,
                      size: Sizes.chatActionIconSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final query = _textEditingController.text.trim();
    // 至少要有文字或圖片之一才送出
    if (query.isEmpty && _selectedImageBytes == null) return;

    final bytes = _selectedImageBytes;
    final mime = _selectedMimeType;

    _textEditingController.clear();
    setState(() {
      _selectedImageBytes = null;
      _selectedMimeType = null;
    });

    context.read<GeminiApiBloc>().add(
      QueryEvent(query: query, imageBytes: bytes, mimeType: mime),
    );
  }
}

// ────────────────────────────────────────────
// 選圖/選檔後的預覽元件
// ────────────────────────────────────────────
class _FilePreview extends StatelessWidget {
  final Uint8List fileBytes;
  final String mimeType;
  final VoidCallback onRemove;

  const _FilePreview({
    required this.fileBytes,
    required this.mimeType,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    final isImage = mimeType.startsWith('image/');

    if (isImage) {
      content = Image.memory(
        fileBytes,
        height: Sizes.imagePreviewSize,
        width: Sizes.imagePreviewSize,
        fit: BoxFit.cover,
      );
    } else {
      final mbSize = (fileBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(
        2,
      );
      content = Container(
        height: Sizes.imagePreviewSize,
        width: Sizes.imagePreviewSize,
        color: ColorName.color1a673ab7,
        padding: const EdgeInsets.all(Sizes.paddingS),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.insert_drive_file,
              color: ColorName.colorFf673ab7,
              size: Sizes.paddingXXL,
            ),
            const SizedBox(height: Sizes.paddingXS),
            Text(
              '$mbSize MB',
              style: const TextStyle(
                fontSize: 12,
                color: ColorName.colorFf673ab7,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(Sizes.paddingM), child: content),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            margin: const EdgeInsets.all(Sizes.paddingXS),
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: ColorName.color8a000000,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: ColorName.colorFfffffff, size: 14),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────
// 訊息氣泡元件
// ────────────────────────────────────────────
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
          maxWidth: MediaQuery.of(context).size.width * Sizes.messageMaxWidthFactor,
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
              blurRadius: 5,
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
                  const Icon(Icons.error_outline, color: ColorName.colorFff44336, size: Sizes.iconS),
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
              imageBuilder: (uri, title, alt) {
                // 支援 data URI 格式的圖片（使用者端嵌入的 base64 圖片）
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
                      color: isAi ? ColorName.colorDd000000 : ColorName.colorFfffffff,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    code: TextStyle(
                      backgroundColor: isAi
                          ? ColorName.colorFfeeeeee
                          : ColorName.colorFf512da8,
                      color: isAi ? ColorName.colorDd000000 : ColorName.colorFfffffff,
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
