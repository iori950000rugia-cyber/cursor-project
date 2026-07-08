/// Remote Config 相当の機能フラグ（ローカル設定で無効化可能）
class FeatureFlags {
  FeatureFlags({required this.hoyolabLinkEnabled});

  /// HoYoLAB 連携全体の ON/OFF（`app_settings.hoyolab_link_enabled`）
  final bool hoyolabLinkEnabled;

  static const defaultHoyolabLinkEnabled = true;

  static const hoyolabLinkEnabledKey = 'hoyolab_link_enabled';
}
