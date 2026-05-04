// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Chat';

  @override
  String get aiAssistantTitle => 'Gemini AI Assistant';

  @override
  String get onlineStatus => 'Online';

  @override
  String get howCanIHelp => 'How can I help you today?';

  @override
  String get typeMessageOrAttach => 'Type a message or attach an image';

  @override
  String get typeMessageHint => 'Type a message...';

  @override
  String get errorLabel => 'Error';

  @override
  String get permissionPhotoTitle => 'Photo Access Required';

  @override
  String get permissionPhotoDesc =>
      'Please go to system settings and allow this app to access your photo library so you can select images to send to the AI.';

  @override
  String get cancel => 'Cancel';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get menuNewChat => 'New Chat';

  @override
  String get menuClearChat => 'Clear Chat';

  @override
  String get menuCopyAll => 'Copy All';

  @override
  String get menuAbout => 'About';

  @override
  String get clearChatTitle => 'Clear all messages?';

  @override
  String get clearChatContent =>
      'This action cannot be undone. All conversation history will be permanently deleted.';

  @override
  String get clearChatConfirm => 'Clear';

  @override
  String get copiedToClipboard => 'Conversation copied';

  @override
  String get searchHint => 'Search messages...';

  @override
  String get noSearchResults => 'No matching messages found';

  @override
  String get startSearching => 'Search through your history';

  @override
  String get menuExport => 'Export Chat';

  @override
  String get exportTxt => 'Plain Text (.txt)';

  @override
  String get exportMd => 'Markdown (.md)';

  @override
  String get exportTitle => 'Select Export Format';

  @override
  String aboutDialogVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String aboutDialogModel(String model) {
    return 'AI Model: $model';
  }
}
