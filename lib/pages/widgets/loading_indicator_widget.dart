import 'package:flutter/material.dart';

import '../../features/foundation/style/sizes.dart';
import '../../gen/colors.gen.dart';

class LoadingIndicatorWidget extends StatelessWidget {
  const LoadingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Sizes.paddingS),
      child: LinearProgressIndicator(
        backgroundColor: ColorName.color00000000,
        valueColor: AlwaysStoppedAnimation<Color>(
          ColorName.colorFf673ab7,
        ),
      ),
    );
  }
}
