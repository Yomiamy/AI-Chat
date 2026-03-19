// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_TW locale. All the
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
  String get localeName => 'zh_TW';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aiAssistantTitle": MessageLookupByLibrary.simpleMessage("Gemini AI 助理"),
    "appTitle": MessageLookupByLibrary.simpleMessage("AI 聊天"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "errorLabel": MessageLookupByLibrary.simpleMessage("錯誤"),
    "goToSettings": MessageLookupByLibrary.simpleMessage("前往設定"),
    "howCanIHelp": MessageLookupByLibrary.simpleMessage("今天能怎麼幫助你？"),
    "onlineStatus": MessageLookupByLibrary.simpleMessage("上線中"),
    "permissionPhotoDesc": MessageLookupByLibrary.simpleMessage(
      "請前往系統設定，允許此 App 存取相片庫，才能選取圖片傳送給 AI。",
    ),
    "permissionPhotoTitle": MessageLookupByLibrary.simpleMessage("需要相片存取權限"),
    "typeMessageHint": MessageLookupByLibrary.simpleMessage("輸入訊息..."),
    "typeMessageOrAttach": MessageLookupByLibrary.simpleMessage("輸入訊息或附上圖片"),
  };
}
