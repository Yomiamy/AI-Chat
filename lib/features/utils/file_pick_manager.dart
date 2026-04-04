import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FilePickManager {
  static final ImagePicker _imagePicker = ImagePicker();

  /// 要求相片權限並開啟相簿選取圖片。
  ///
  /// 回傳 [XFile] 如果成功選取，否則回傳 null。
  /// 若權限被永久拒絕，[onPermissionDenied] 會被呼叫，
  /// 由呼叫端（Widget 層）負責顯示說明對話框。
  static Future<XFile?> pickImageWithPermission({
    VoidCallback? onPermissionDenied,
  }) async {
    // [Linus] 記住：不要再改回 Permission.storage 了！
    // Android 13 (API 33+) 已經廢棄了 READ_EXTERNAL_STORAGE，如果你請求它，系統會直接無視並回傳 denied。
    // permission_handler 已經幫你處理好向下相容：
    // 你只管請求 Permission.photos，如果在舊手機上它會自動去要 READ_EXTERNAL_STORAGE。
    final permission = Permission.photos;

    final status = await permission.status;

    if (status.isPermanentlyDenied) {
      onPermissionDenied?.call();
      return null;
    }

    if (!status.isGranted) {
      final result = await permission.request();
      if (!result.isGranted) {
        onPermissionDenied?.call();
        return null;
      }
    }

    // 授權後才開啟相片選擇器
    return await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  /// 開啟系統檔案選擇器選取一般檔案 (PDF, TXT 等)
  ///
  /// 一般取檔在現代系統中透過內建的 Document Picker 直接處理，無需額外的應用程式層級權限。
  static Future<FilePickerResult?> pickFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true, // 為了讓網頁或部分平台能直接拿 bytes
    );
  }
}
