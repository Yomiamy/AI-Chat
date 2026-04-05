import 'package:ai_chat/bloc/bloc.dart';
import 'package:ai_chat/generated/assets/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../features/foundation/style/sizes.dart';
import '../../../generated/l10n.dart';

class InputAreaWidget extends StatefulWidget {
  const InputAreaWidget({super.key});

  @override
  State<InputAreaWidget> createState() => _InputAreaWidgetState();
}

class _InputAreaWidgetState extends State<InputAreaWidget> {
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeminiApiBloc, GeminiApiState>(
      builder: (context, state) {
        final selectedImageBytes = state.selectedFileBytes;
        final selectedMimeType = state.selectedMimeType;

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
                blurRadius: Sizes.shadowBlurM,
                offset: const Offset(0, -Sizes.paddingXS),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedImageBytes != null) ...[
                _FilePreview(
                  fileBytes: selectedImageBytes,
                  mimeType: selectedMimeType ?? 'application/octet-stream',
                  onRemove: () => context.read<GeminiApiBloc>().add(
                    GeminiApiRemoveFileEvent(),
                  ),
                ),
                const SizedBox(height: Sizes.paddingS),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => context.read<GeminiApiBloc>().add(
                      GeminiApiPickImageEvent(
                        onPermissionDenied: () => _showPermissionDialog(context),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(Sizes.paddingSM),
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
                  GestureDetector(
                    onTap: () => context.read<GeminiApiBloc>().add(GeminiApiPickFileEvent()),
                    child: Container(
                      padding: const EdgeInsets.all(Sizes.paddingSM),
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
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sizes.paddingL,
                      ),
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
                            hintStyle: const TextStyle(
                              color: ColorName.color61000000,
                            ),
                          ),
                          maxLines: null,
                          onSubmitted: (value) => _sendMessage(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Sizes.paddingSM),
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
      },
    );
  }

  void _showPermissionDialog(BuildContext context) {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.current.permissionPhotoTitle),
        content: Text(S.current.permissionPhotoDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.current.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: Text(S.current.goToSettings),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final query = _textEditingController.text.trim();
    final state = context.read<GeminiApiBloc>().state;

    if (query.isEmpty && state.selectedFileBytes == null) return;

    _textEditingController.clear();

    context.read<GeminiApiBloc>().add(GeminiApiQueryEvent(query: query));
  }
}

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
              size: Sizes.iconL,
            ),
            const SizedBox(height: Sizes.paddingXS),
            Text(
              '$mbSize MB',
              style: const TextStyle(
                fontSize: Sizes.textS,
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
        ClipRRect(
          borderRadius: BorderRadius.circular(Sizes.paddingM),
          child: content,
        ),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            margin: const EdgeInsets.all(Sizes.paddingXS),
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: ColorName.color8a000000,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              color: ColorName.colorFfffffff,
              size: Sizes.iconSM,
            ),
          ),
        ),
      ],
    );
  }
}
