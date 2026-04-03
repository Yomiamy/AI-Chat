import 'dart:ui' as ui;

import 'package:ai_chat/pages/ai_chat_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ai_chat/generated/l10n.dart';
import 'package:ai_chat/gen/colors.gen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  await _initLocale();
  
  runApp(const MyApp());
}

Future _initLocale() async {
// 去底層抓系統目前的預設語言
  final systemLocale = ui.PlatformDispatcher.instance.locale;
  // 手動逼它先載入
  await S.load(systemLocale);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.current.appTitle,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorName.colorFf673ab7),
        useMaterial3: true,
      ),
      home: const AiChatPage(),
    );
  }
}
