import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static final ImagePicker _imagePicker = ImagePicker();

  /// 要求相片權限並開啟相簿選取圖片。
  /// 
  /// 回傳 [XFile] 如果成功選取，否則回傳 null。
  static Future<XFile?> pickImageWithPermission(BuildContext context) async {
    // [Linus] 記住：不要再改回 Permission.storage 了！
    // Android 13 (API 33+) 已經廢棄了 READ_EXTERNAL_STORAGE，如果你請求它，系統會直接無視並回傳 denied。
    // permission_handler 已經幫你處理好向下相容：
    // 你只管請求 Permission.photos，如果在舊手機上它會自動去要 READ_EXTERNAL_STORAGE。
    final permission = Permission.photos;

    final status = await permission.status;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDialog(context);
      }
      return null;
    }

    if (!status.isGranted) {
      final result = await permission.request();
      if (!result.isGranted) {
        if (context.mounted) {
          _showPermissionDialog(context);
        }
        return null;
      }
    }

    // 授權後才開啟相片選擇器
    return await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  static void _showPermissionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('需要相片存取權限'),
        content: const Text('請前往系統設定，允許此 App 存取相片庫，才能選取圖片傳送給 AI。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('前往設定'),
          ),
        ],
      ),
    );
  }
}
