import 'package:ai_chat/generated/assets/colors.gen.dart';
import 'package:flutter/material.dart';

import '../../../features/foundation/style/sizes.dart';
import '../../../generated/l10n.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: Sizes.paddingXL),
          Text(
            S.current.howCanIHelp,
            style: const TextStyle(
              fontSize: Sizes.textXXL,
              fontWeight: FontWeight.bold,
              color: ColorName.colorDd000000,
            ),
          ),
          const SizedBox(height: Sizes.paddingM),
          Text(
            S.current.typeMessageOrAttach,
            style: const TextStyle(
              fontSize: Sizes.textL,
              color: ColorName.color8a000000,
            ),
          ),
        ],
      ),
    );
  }
}
