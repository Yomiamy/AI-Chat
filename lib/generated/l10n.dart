// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `AI Chat`
  String get appTitle {
    return Intl.message('AI Chat', name: 'appTitle', desc: '', args: []);
  }

  /// `Gemini AI Assistant`
  String get aiAssistantTitle {
    return Intl.message(
      'Gemini AI Assistant',
      name: 'aiAssistantTitle',
      desc: '',
      args: [],
    );
  }

  /// `Online`
  String get onlineStatus {
    return Intl.message('Online', name: 'onlineStatus', desc: '', args: []);
  }

  /// `How can I help you today?`
  String get howCanIHelp {
    return Intl.message(
      'How can I help you today?',
      name: 'howCanIHelp',
      desc: '',
      args: [],
    );
  }

  /// `Type a message or attach an image`
  String get typeMessageOrAttach {
    return Intl.message(
      'Type a message or attach an image',
      name: 'typeMessageOrAttach',
      desc: '',
      args: [],
    );
  }

  /// `Type a message...`
  String get typeMessageHint {
    return Intl.message(
      'Type a message...',
      name: 'typeMessageHint',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get errorLabel {
    return Intl.message('Error', name: 'errorLabel', desc: '', args: []);
  }

  /// `Photo Access Required`
  String get permissionPhotoTitle {
    return Intl.message(
      'Photo Access Required',
      name: 'permissionPhotoTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please go to system settings and allow this app to access your photo library so you can select images to send to the AI.`
  String get permissionPhotoDesc {
    return Intl.message(
      'Please go to system settings and allow this app to access your photo library so you can select images to send to the AI.',
      name: 'permissionPhotoDesc',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Go to Settings`
  String get goToSettings {
    return Intl.message(
      'Go to Settings',
      name: 'goToSettings',
      desc: '',
      args: [],
    );
  }

  /// `New Chat`
  String get menuNewChat {
    return Intl.message('New Chat', name: 'menuNewChat', desc: '', args: []);
  }

  /// `Clear Chat`
  String get menuClearChat {
    return Intl.message(
      'Clear Chat',
      name: 'menuClearChat',
      desc: '',
      args: [],
    );
  }

  /// `Copy All`
  String get menuCopyAll {
    return Intl.message('Copy All', name: 'menuCopyAll', desc: '', args: []);
  }

  /// `About`
  String get menuAbout {
    return Intl.message('About', name: 'menuAbout', desc: '', args: []);
  }

  /// `Clear all messages?`
  String get clearChatTitle {
    return Intl.message(
      'Clear all messages?',
      name: 'clearChatTitle',
      desc: '',
      args: [],
    );
  }

  /// `This action cannot be undone. All conversation history will be permanently deleted.`
  String get clearChatContent {
    return Intl.message(
      'This action cannot be undone. All conversation history will be permanently deleted.',
      name: 'clearChatContent',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get clearChatConfirm {
    return Intl.message('Clear', name: 'clearChatConfirm', desc: '', args: []);
  }

  /// `Conversation copied`
  String get copiedToClipboard {
    return Intl.message(
      'Conversation copied',
      name: 'copiedToClipboard',
      desc: '',
      args: [],
    );
  }

  /// `Search messages...`
  String get searchHint {
    return Intl.message(
      'Search messages...',
      name: 'searchHint',
      desc: '',
      args: [],
    );
  }

  /// `No matching messages found`
  String get noSearchResults {
    return Intl.message(
      'No matching messages found',
      name: 'noSearchResults',
      desc: '',
      args: [],
    );
  }

  /// `Search through your history`
  String get startSearching {
    return Intl.message(
      'Search through your history',
      name: 'startSearching',
      desc: '',
      args: [],
    );
  }

  /// `Export Chat`
  String get menuExport {
    return Intl.message('Export Chat', name: 'menuExport', desc: '', args: []);
  }

  /// `Plain Text (.txt)`
  String get exportTxt {
    return Intl.message(
      'Plain Text (.txt)',
      name: 'exportTxt',
      desc: '',
      args: [],
    );
  }

  /// `Markdown (.md)`
  String get exportMd {
    return Intl.message('Markdown (.md)', name: 'exportMd', desc: '', args: []);
  }

  /// `Select Export Format`
  String get exportTitle {
    return Intl.message(
      'Select Export Format',
      name: 'exportTitle',
      desc: '',
      args: [],
    );
  }

  /// `Version {version} (build {build})`
  String aboutDialogVersion(String version, String build) {
    return Intl.message(
      'Version $version (build $build)',
      name: 'aboutDialogVersion',
      desc: '',
      args: [version, build],
    );
  }

  /// `AI Model: {model}`
  String aboutDialogModel(String model) {
    return Intl.message(
      'AI Model: $model',
      name: 'aboutDialogModel',
      desc: '',
      args: [model],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
