import 'dart:ui' as ui;

import 'package:ai_chat/generated/assets/colors.gen.dart';
import 'package:ai_chat/pages/ai_chat_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ai_chat/generated/l10n.dart';

import 'di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initLocale();
  await configureDependencies();

  runApp(const MyApp());
}

Future _initLocale() async {
  final systemLocale = ui.PlatformDispatcher.instance.locale;
  await S.load(systemLocale);
}

class MyApp extends StatelessWidget {

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
