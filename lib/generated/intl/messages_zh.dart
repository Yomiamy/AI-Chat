// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
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
  String get localeName => 'zh';

  static String m0(model) => "AI 模型：${model}";

  static String m1(version, build) => "版本 ${version} (build ${build})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutDialogModel": m0,
    "aboutDialogVersion": m1,
    "aiAssistantTitle": MessageLookupByLibrary.simpleMessage("Gemini AI 助理"),
    "appTitle": MessageLookupByLibrary.simpleMessage("AI 聊天"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "clearChatConfirm": MessageLookupByLibrary.simpleMessage("清除"),
    "clearChatContent": MessageLookupByLibrary.simpleMessage(
      "此操作無法復原，所有對話記錄將被永久刪除。",
    ),
    "clearChatTitle": MessageLookupByLibrary.simpleMessage("清除所有對話？"),
    "copiedToClipboard": MessageLookupByLibrary.simpleMessage("已複製對話記錄"),
    "errorLabel": MessageLookupByLibrary.simpleMessage("錯誤"),
    "exportMd": MessageLookupByLibrary.simpleMessage("Markdown (.md)"),
    "exportTitle": MessageLookupByLibrary.simpleMessage("選擇匯出格式"),
    "exportTxt": MessageLookupByLibrary.simpleMessage("純文字 (.txt)"),
    "goToSettings": MessageLookupByLibrary.simpleMessage("前往設定"),
    "howCanIHelp": MessageLookupByLibrary.simpleMessage("今天能怎麼幫助你？"),
    "menuAbout": MessageLookupByLibrary.simpleMessage("關於"),
    "menuClearChat": MessageLookupByLibrary.simpleMessage("清除對話"),
    "menuCopyAll": MessageLookupByLibrary.simpleMessage("複製對話"),
    "menuExport": MessageLookupByLibrary.simpleMessage("匯出對話"),
    "menuNewChat": MessageLookupByLibrary.simpleMessage("新對話"),
    "noSearchResults": MessageLookupByLibrary.simpleMessage("找不到相關對話"),
    "onlineStatus": MessageLookupByLibrary.simpleMessage("上線中"),
    "permissionPhotoDesc": MessageLookupByLibrary.simpleMessage(
      "請前往系統設定，允許此 App 存取相片庫，才能選取圖片傳送給 AI。",
    ),
    "permissionPhotoTitle": MessageLookupByLibrary.simpleMessage("需要相片存取權限"),
    "searchHint": MessageLookupByLibrary.simpleMessage("搜尋對話..."),
    "startSearching": MessageLookupByLibrary.simpleMessage("搜尋歷史紀錄"),
    "typeMessageHint": MessageLookupByLibrary.simpleMessage("輸入訊息..."),
    "typeMessageOrAttach": MessageLookupByLibrary.simpleMessage("輸入訊息或附上圖片"),
  };
}
