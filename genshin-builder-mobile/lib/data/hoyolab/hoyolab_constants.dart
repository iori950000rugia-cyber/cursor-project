class HoyolabConstants {
  HoyolabConstants._();

  static const defaultAppVersion = '4.13.0';
  static const language = 'ja-jp';
  static const loginUrl = 'https://act.hoyolab.com/ys/app/interactive-map/index.html';
  static const cookieUrl = 'https://act.hoyolab.com';

  static const verifyLTokenUrl =
      'https://passport-api-sg.hoyolab.com/account/ma-passport/token/verifyLToken';
  static const getUserGameRolesUrl =
      'https://api-account-os.hoyolab.com/binding/api/getUserGameRolesByLtoken';
  static const dailyNoteUrl =
      'https://bbs-api-os.hoyolab.com/game_record/app/genshin/api/dailyNote';
  static const getAllRegionsUrl =
      'https://api-account-os.hoyolab.com/account/binding/api/getAllRegions';

  /// サイレント扱い（ユーザー向けに簡潔メッセージへ変換）
  static const knownRetcodes = {
    -100, // login expired
    10102, // realtime notes off
    -502001, // character not exist
    -502002, // character data private
  };
}
