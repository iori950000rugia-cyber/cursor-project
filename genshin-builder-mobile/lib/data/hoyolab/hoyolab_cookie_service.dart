import 'package:webview_flutter/webview_flutter.dart';

import 'hoyolab_constants.dart';

/// WebView から HoYoLAB Cookie を取得（Android / iOS）
class HoyolabCookieService {
  const HoyolabCookieService();

  Future<String?> fetchCookieString() async {
    final manager = WebViewCookieManager();
    final cookies = await manager.getCookies(
      domain: Uri.parse(HoyolabConstants.cookieUrl),
    );
    if (cookies.isEmpty) return null;

    final parts = <String>[];
    for (final cookie in cookies) {
      if (cookie.name.isEmpty) continue;
      parts.add('${cookie.name}=${cookie.value}');
    }
    if (parts.isEmpty) return null;
    return '${parts.join('; ')};';
  }

  Future<bool> hasAuthCookie() async {
    final cookie = await fetchCookieString();
    if (cookie == null) return false;
    return cookie.contains('ltoken=') ||
        cookie.contains('ltuid_v2=') ||
        cookie.contains('account_id_v2=');
  }
}
