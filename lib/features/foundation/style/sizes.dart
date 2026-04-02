import 'package:flutter/material.dart';

/// 集中管理應用程式中使用的尺寸、間距、圓角等常量。
/// 參照 Eslite-v3 的設置方式，消除 UI 代碼中的硬編碼數字。
class Sizes {
  // ────────────────────────────────────────────
  // 基礎尺寸 (General)
  // ────────────────────────────────────────────
  static const zero = 0.0;
  static const divider = 0.1;
  static const dividerXXXS = 0.5;
  static const dividerXXS = 1.0;
  static const dividerXS = 2.0;
  static const dividerS = 10.0;

  // ────────────────────────────────────────────
  // 圓角 (Radius)
  // ────────────────────────────────────────────
  static const radiusXS = 2.0;
  static const radiusS = 4.0;
  static const radiusM = 8.0;
  static const radiusL = 16.0;
  static const radiusXL = 24.0;
  static const radiusXXL = 32.0;

  // ────────────────────────────────────────────
  // 圖示尺寸 (Icons)
  // ────────────────────────────────────────────
  static const iconXXS = 8.0;
  static const iconXS = 12.0;
  static const iconS = 16.0;
  static const iconM = 24.0;
  static const iconXM = 28.0;
  static const iconL = 32.0;
  static const iconXL = 40.0;
  static const iconXXL = 48.0;
  static const iconXXXL = 64.0;
  static const iconXXXXL = 72.0;
  static const iconXXXXXL = 96.0;

  // ────────────────────────────────────────────
  // 間距與內邊距 (Padding/Margin)
  // ────────────────────────────────────────────
  static const paddingXXXS = 1.0;
  static const paddingXXS = 2.0;
  static const paddingXS = 4.0;
  static const paddingS = 8.0;
  static const paddingM = 12.0;
  static const paddingL = 16.0;
  static const paddingNegL = -1 * paddingL;
  static const paddingXL = 24.0;
  static const paddingXXL = 32.0;
  static const paddingXXXL = 64.0;
  static const paddingXXXXL = 72.0;
  static const paddingXXXXXL = 90.0;

  // ────────────────────────────────────────────
  // 字體大小 (Typography)
  // ────────────────────────────────────────────
  static const textXS  = 10.0;
  static const textS   = 12.0;
  static const textM   = 14.0;
  static const textL   = 16.0;
  static const textXL  = 18.0;
  static const textXXL = 20.0;
  static const textBody = 15.0;

  // ────────────────────────────────────────────
  // 陰影模糊 (Shadow Blur)
  // ────────────────────────────────────────────
  static const shadowBlurS = 4.0;
  static const shadowBlurM = 10.0;
  static const shadowBlurL = 20.0;

  // ────────────────────────────────────────────
  // 陰影與海拔 (Elevation)
  // ────────────────────────────────────────────
  static const elevationXS = 1.0;
  static const elevationS = 2.0;
  static const elevationM = 4.0;
  static const elevationL = 8.0;
  static const elevationXL = 16.0;

  // ────────────────────────────────────────────
  // 描邊 (Stroke)
  // ────────────────────────────────────────────
  static const strokeXS = 1.0;
  static const strokeS = 2.0;
  static const strokeM = 4.0;
  static const strokeL = 6.0;

  // ────────────────────────────────────────────
  // AI Chat 專用尺寸 (Project Specific)
  // ────────────────────────────────────────────
  static const avatarRadius = 44.0;
  static const chatBubbleRadius = 20.0;
  static const chatActionIconSize = 22.0;
  static const chatHeaderIconSize = 20.0;
  static const imagePreviewSize = 100.0;
  static const messageMaxWidthFactor = 0.8;
  static const listPaddingV = 20.0;

  // ────────────────────────────────────────────
  // 輔助方法
  // ────────────────────────────────────────────
  static Size appBar({required double appBarHeight, double? bottomHeight}) {
    double height = appBarHeight;
    if (bottomHeight != null) {
      height += bottomHeight + paddingS;
    }
    return Size.fromHeight(height);
  }
}
