import 'hoyolab_constants.dart';

class HoyolabApiException implements Exception {
  const HoyolabApiException(this.retcode, this.originalMessage);

  final int retcode;
  final String originalMessage;

  bool get isSilent => HoyolabConstants.knownRetcodes.contains(retcode);

  String get userMessage => switch (retcode) {
        -100 => 'ログインの有効期限が切れました。再ログインしてください。',
        10102 =>
          'リアルタイムメモが非公開です。HoYoLAB のゲーム記録で公開設定を有効にしてください。',
        -502001 => 'キャラクターが見つかりません。UID を確認してください。',
        -502002 => 'キャラクターデータが非公開です。HoYoLAB で公開設定を確認してください。',
        _ => 'HoYoLAB API エラー ($retcode)',
      };

  @override
  String toString() => 'HoyolabApiException($retcode)';
}
