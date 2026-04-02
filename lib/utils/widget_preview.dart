import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../generated/l10n.dart';

/// Preview 語系設定：繁體中文 + 所有必要的 delegate。
///
/// 必須是 public top-level function，才能被 const Preview(localizations: ...) 引用。
PreviewLocalizationsData zhTwLocalizations() => PreviewLocalizationsData(
      locale: const Locale('zh', 'TW'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );

/// 跨機型 MultiPreview：涵蓋主流 Android / iOS 裝置尺寸，
/// 每個 Preview 都已套用繁體中文語系。
final class DevicePreviewAll extends MultiPreview {
  const DevicePreviewAll();

  @override
  List<Preview> get previews => const [
    // ── Android ──────────────────────────────────────────
    Preview(name: 'Pixel 7',          size: Size(412, 915), group: 'Android', localizations: zhTwLocalizations),
    Preview(name: 'Pixel 8a',         size: Size(384, 832), group: 'Android', localizations: zhTwLocalizations),
    Preview(name: 'Galaxy S24',       size: Size(360, 780), group: 'Android', localizations: zhTwLocalizations),

    // ── iOS ──────────────────────────────────────────────
    Preview(name: 'iPhone SE (3rd)',  size: Size(375, 667), group: 'iOS', localizations: zhTwLocalizations),
    Preview(name: 'iPhone 16',        size: Size(393, 852), group: 'iOS', localizations: zhTwLocalizations),
    Preview(name: 'iPhone 16 Plus',   size: Size(430, 932), group: 'iOS', localizations: zhTwLocalizations),
    Preview(name: 'iPhone 16 Pro',    size: Size(402, 874), group: 'iOS', localizations: zhTwLocalizations),
    Preview(name: 'iPhone 16 Pro Max',size: Size(440, 956), group: 'iOS', localizations: zhTwLocalizations),
    Preview(name: 'iPhone 16e',       size: Size(375, 667), group: 'iOS', localizations: zhTwLocalizations),
  ];
}
