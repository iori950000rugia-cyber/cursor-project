import 'package:flutter_test/flutter_test.dart';
import 'package:genshin_builder_mobile/core/errors/user_facing_error.dart';

void main() {
  test('unexpected exception details are not exposed to users', () {
    const fallback = 'safe fallback';
    final message = userFacingError(
      Exception('ltoken_v2=secret-value at /private/path'),
      fallback: fallback,
    );

    expect(message, fallback);
    expect(message, isNot(contains('secret-value')));
  });
}
