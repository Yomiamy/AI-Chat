// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(model) => "AI Model: ${model}";

  static String m1(version, build) => "Version ${version} (build ${build})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutDialogModel": m0,
    "aboutDialogVersion": m1,
    "aiAssistantTitle": MessageLookupByLibrary.simpleMessage(
      "Gemini AI Assistant",
    ),
    "appTitle": MessageLookupByLibrary.simpleMessage("AI Chat"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "clearChatConfirm": MessageLookupByLibrary.simpleMessage("Clear"),
    "clearChatContent": MessageLookupByLibrary.simpleMessage(
      "This action cannot be undone. All conversation history will be permanently deleted.",
    ),
    "clearChatTitle": MessageLookupByLibrary.simpleMessage(
      "Clear all messages?",
    ),
    "copiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Conversation copied",
    ),
    "errorLabel": MessageLookupByLibrary.simpleMessage("Error"),
    "exportMd": MessageLookupByLibrary.simpleMessage("Markdown (.md)"),
    "exportTitle": MessageLookupByLibrary.simpleMessage("Select Export Format"),
    "exportTxt": MessageLookupByLibrary.simpleMessage("Plain Text (.txt)"),
    "goToSettings": MessageLookupByLibrary.simpleMessage("Go to Settings"),
    "howCanIHelp": MessageLookupByLibrary.simpleMessage(
      "How can I help you today?",
    ),
    "menuAbout": MessageLookupByLibrary.simpleMessage("About"),
    "menuClearChat": MessageLookupByLibrary.simpleMessage("Clear Chat"),
    "menuCopyAll": MessageLookupByLibrary.simpleMessage("Copy All"),
    "menuExport": MessageLookupByLibrary.simpleMessage("Export Chat"),
    "menuNewChat": MessageLookupByLibrary.simpleMessage("New Chat"),
    "noSearchResults": MessageLookupByLibrary.simpleMessage(
      "No matching messages found",
    ),
    "onlineStatus": MessageLookupByLibrary.simpleMessage("Online"),
    "permissionPhotoDesc": MessageLookupByLibrary.simpleMessage(
      "Please go to system settings and allow this app to access your photo library so you can select images to send to the AI.",
    ),
    "permissionPhotoTitle": MessageLookupByLibrary.simpleMessage(
      "Photo Access Required",
    ),
    "searchHint": MessageLookupByLibrary.simpleMessage("Search messages..."),
    "startSearching": MessageLookupByLibrary.simpleMessage(
      "Search through your history",
    ),
    "typeMessageHint": MessageLookupByLibrary.simpleMessage(
      "Type a message...",
    ),
    "typeMessageOrAttach": MessageLookupByLibrary.simpleMessage(
      "Type a message or attach an image",
    ),
  };
}
