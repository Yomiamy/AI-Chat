import 'dart:convert';
import 'package:ai_chat/generated/assets/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/bloc.dart';
import '../../features/foundation/style/sizes.dart';
import '../../generated/l10n.dart';

class MessageBubbleWidget extends StatelessWidget {
  final String message;

  const MessageBubbleWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isAi = ChatEntryPrefix.aiReply.matches(message);
    final bool isError = ChatEntryPrefix.error.matches(message);
    final String content = isAi
        ? ChatEntryPrefix.aiReply.strip(message)
        : ChatEntryPrefix.prompt.strip(message);

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
