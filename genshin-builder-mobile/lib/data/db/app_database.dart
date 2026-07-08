/// DB エントリポイント。
///
/// 現状は sqflite 実装（[sqflite_database.dart]）。
/// `dart run build_runner build` 後に [drift/app_database.dart] へ切り替える。
export 'sqflite_database.dart';
