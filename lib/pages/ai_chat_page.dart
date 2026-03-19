import 'dart:convert';
import 'dart:io';

import 'package:ai_chat/gen/assets.gen.dart';
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.current.aiAssistantTitle,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  S.current.onlineStatus,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
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
                            horizontal: 16,
                            vertical: 20,
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
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple,
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
            radius: 44,
            backgroundColor: Color(0x1A7C3AED),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 44,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 24),
          Text(
            S.current.howCanIHelp,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            S.current.typeMessageOrAttach,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
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
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 選圖按鈕
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Colors.deepPurple,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 一般檔案按鈕
              GestureDetector(
                onTap: _pickGeneralFile,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.attach_file,
                    color: Colors.deepPurple,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 文字輸入框
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F6),
                    borderRadius: BorderRadius.circular(24),
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
                        hintStyle: const TextStyle(color: Colors.black38),
                      ),
                      maxLines: null,
                      onSubmitted: (value) => _sendMessage(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 送出按鈕
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => _sendMessage(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 22,
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
        height: 100,
        width: 100,
        fit: BoxFit.cover,
      );
    } else {
      final mbSize = (fileBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(
        2,
      );
      content = Container(
        height: 100,
        width: 100,
        color: Colors.deepPurple.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.insert_drive_file,
              color: Colors.deepPurple,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '$mbSize MB',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.deepPurple,
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
        ClipRRect(borderRadius: BorderRadius.circular(12), child: content),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
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
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAi ? Colors.white : Colors.deepPurple,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAi ? 0 : 20),
            bottomRight: Radius.circular(isAi ? 20 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    S.current.errorLabel,
                    style: const TextStyle(
                      color: Colors.red,
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
                        borderRadius: BorderRadius.circular(8),
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
                      color: isAi ? Colors.black87 : Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    code: TextStyle(
                      backgroundColor: isAi
                          ? Colors.grey[200]
                          : Colors.deepPurple[700],
                      color: isAi ? Colors.black87 : Colors.white,
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
