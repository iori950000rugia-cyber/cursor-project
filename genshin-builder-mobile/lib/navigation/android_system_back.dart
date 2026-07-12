import 'package:flutter/foundation.dart';

/// Android のシステム Back を AppShell で扱うか。
///
/// Web では [defaultTargetPlatform] が Android になり得るため [kIsWeb] で除外する。
bool get isAndroidSystemBackHandlingEnabled =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Shell 内のホーム loc（`/`）。
bool isShellHomePath(String path) => path == '/' || path.isEmpty;

/// ネストした Shell 子ルートか（通常 pop 可能）。
///
/// `GoRouter.canPop()` は Shell build 時点で false のまま残ることがあるため、
/// 既知の nested path で判定する。
bool isShellNestedLocation(String path) {
  if (path.startsWith('/characters/') && path.length > '/characters/'.length) {
    return true;
  }
  if (path.startsWith('/settings/') && path.length > '/settings/'.length) {
    return true;
  }
  return false;
}

/// Predictive Back 向け: フレームワークに通常 pop を任せるか。
bool androidSystemBackCanPop({
  required String locationPath,
  required bool isEndDrawerOpen,
}) {
  if (isEndDrawerOpen) return false;
  return isShellNestedLocation(locationPath);
}

/// `canPop == false` かつ didPop == false のとき Drawer を閉じるべきか。
bool androidSystemBackShouldCloseDrawer({
  required bool didPop,
  required bool isEndDrawerOpen,
}) =>
    !didPop && isEndDrawerOpen;

/// `canPop == false` かつ didPop == false のとき Home へ `go` すべきか。
bool androidSystemBackShouldGoHome({
  required String locationPath,
  required bool isEndDrawerOpen,
}) {
  if (isEndDrawerOpen) return false;
  if (isShellNestedLocation(locationPath)) return false;
  return !isShellHomePath(locationPath);
}
