// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AI 聊天';

  @override
  String get aiAssistantTitle => 'Gemini AI 助理';

  @override
  String get onlineStatus => '上線中';

  @override
  String get howCanIHelp => '今天能怎麼幫助你？';

  @override
  String get typeMessageOrAttach => '輸入訊息或附上圖片';

  @override
  String get typeMessageHint => '輸入訊息...';

  @override
  String get errorLabel => '錯誤';

  @override
  String get permissionPhotoTitle => '需要相片存取權限';

  @override
  String get permissionPhotoDesc => '請前往系統設定，允許此 App 存取相片庫，才能選取圖片傳送給 AI。';

  @override
  String get cancel => '取消';

  @override
  String get goToSettings => '前往設定';

  @override
  String get menuNewChat => '新對話';

  @override
  String get menuClearChat => '清除對話';

  @override
  String get menuCopyAll => '複製對話';

  @override
  String get menuAbout => '關於';

  @override
  String get clearChatTitle => '清除所有對話？';

  @override
  String get clearChatContent => '此操作無法復原，所有對話記錄將被永久刪除。';

  @override
  String get clearChatConfirm => '清除';

  @override
  String get copiedToClipboard => '已複製對話記錄';

  @override
  String get searchHint => '搜尋對話...';

  @override
  String get noSearchResults => '找不到相關對話';

  @override
  String get startSearching => '搜尋歷史紀錄';

  @override
  String get menuExport => '匯出對話';

  @override
  String get exportTxt => '純文字 (.txt)';

  @override
  String get exportMd => 'Markdown (.md)';

  @override
  String get exportTitle => '選擇匯出格式';

  @override
  String aboutDialogVersion(String version, String build) {
    return '版本 $version (build $build)';
  }

  @override
  String aboutDialogModel(String model) {
    return 'AI 模型：$model';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'AI 聊天';

  @override
  String get aiAssistantTitle => 'Gemini AI 助理';

  @override
  String get onlineStatus => '上線中';

  @override
  String get howCanIHelp => '今天能怎麼幫助你？';

  @override
  String get typeMessageOrAttach => '輸入訊息或附上圖片';

  @override
  String get typeMessageHint => '輸入訊息...';

  @override
  String get errorLabel => '錯誤';

  @override
  String get permissionPhotoTitle => '需要相片存取權限';

  @override
  String get permissionPhotoDesc => '請前往系統設定，允許此 App 存取相片庫，才能選取圖片傳送給 AI。';

  @override
  String get cancel => '取消';

  @override
  String get goToSettings => '前往設定';

  @override
  String get menuNewChat => '新對話';

  @override
  String get menuClearChat => '清除對話';

  @override
  String get menuCopyAll => '複製對話';

  @override
  String get menuAbout => '關於';

  @override
  String get clearChatTitle => '清除所有對話？';

  @override
  String get clearChatContent => '此操作無法復原，所有對話記錄將被永久刪除。';

  @override
  String get clearChatConfirm => '清除';

  @override
  String get copiedToClipboard => '已複製對話記錄';

  @override
  String get searchHint => '搜尋對話...';

  @override
  String get noSearchResults => '找不到相關對話';

  @override
  String get startSearching => '搜尋歷史紀錄';

  @override
  String get menuExport => '匯出對話';

  @override
  String get exportTxt => '純文字 (.txt)';

  @override
  String get exportMd => 'Markdown (.md)';

  @override
  String get exportTitle => '選擇匯出格式';

  @override
  String aboutDialogVersion(String version, String build) {
    return '版本 $version (build $build)';
  }

  @override
  String aboutDialogModel(String model) {
    return 'AI 模型：$model';
  }
}
